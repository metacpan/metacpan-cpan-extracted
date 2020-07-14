package App::Acmeman::Apache::Layout::slackware;
use strict;
use warnings;
use Carp;
use parent 'App::Acmeman::Apache::Layout';
use Apache::Config::Preproc;
use App::Acmeman::Log qw(:all);
use File::BackupCopy;

our $PRIORITY = 10;

sub new {
    my $class = shift;
    my $ap = shift;

    if ($ap->server_config eq  '/etc/httpd/httpd.conf'
	&& -d '/etc/httpd/extra') {
	return $class->SUPER::new($ap,
			incdir => '/etc/httpd/extra',
			restart_command => '/etc/rc.d/rc.httpd restart'
	       );
    }
}

sub post_setup {
    my ($self,$filename) = @_;

    my $master_config_file = $self->config_file;
    my $app = new Apache::Config::Preproc(
        $master_config_file,
	'-no-comment-grouping',
        -expand => [ 'locus',
                     { 'include' => [ server_root => $self->apache->server_root ] },
                     { 'macro' => [
			   'keep' => [ qw(LetsEncryptChallenge
                                          LetsEncryptReference
                                          LetsEncryptSSL)
			             ]
		       ]
		     }
	           ])
	or do {
	    debug(1, "can't parse apache configuration: $Apache::Admin::Config::ERROR");
	    return;
    };

    my $need_macro_module = !$self->apache_modules('macro');
    my $letsencrypt_macro_loaded = grep {
	$_->value =~ /^letsencrypt(?:challenge|reference|ssl)/i
    } $app->select('section', 'Macro');

    debug(3, "Need macro module? ".($need_macro_module?'yes':'no'));
    debug(3, "Need letsencrypt macro? ".
          ($letsencrypt_macro_loaded==0
	   ? 'yes'
	   : ($letsencrypt_macro_loaded==3
	      ? 'no' : 'perhaps')));

    my $last_loadmodule;
    my $stop_search;
    my $last_master_locus;
    my $include_text = "Include $filename";

    foreach my $node ($app->select) {
	if (!$stop_search) {
	    if (($node->locus->filenames)[0] eq $master_config_file) {
		$last_master_locus = $node->locus;
	    }
	    if ($node->type eq 'section') {
		if ($node->name =~ /^virtualhost$/i) {
		    $stop_search = $last_master_locus;
		    last;
		}
	    }
	}

	if ($node->type eq 'comment') {
	    if ($node->value =~ m{^\s*loadmodule\s}) {
		$last_loadmodule = $node->locus;
	    }
	} elsif ($node->type eq 'directive') {
	    if ($node->name =~ /^loadmodule$/i) {
		$last_loadmodule = $node->locus;
	    }
	}
	
	if ($need_macro_module) {
	    if ($node->type eq 'comment') {
		if ($node->value =~ m{^\s*(loadmodule\s+macro_module\s.*)}i) {
		    debug(3, "Will uncomment ".$node->locus. " ".$node->value);
		    $self->add_command($node->locus, \&_replace_directive_at, $1);
		    $last_loadmodule = $node->locus;
		    $need_macro_module = 0;
		}
	    }
	}
	
	if (!$letsencrypt_macro_loaded) {
	    if ($node->type eq 'directive'
		&& $node->name =~ /^include/i
		&& $node->value =~ m{^.+/httpd-vhosts.conf\s*$}) {
		my $locus = $node->locus->has_file($master_config_file)
		    ? $node->locus : $last_master_locus;
		debug(3, "Will insert \"$include_text\" before $locus");
		$self->add_command($locus, \&_insert_directive_before,
				   $include_text);
		$letsencrypt_macro_loaded = 3;
	    }
	}
    }

    if ($need_macro_module && $last_loadmodule) {
	debug(3, "Will insert a LoadModule directive after ".$last_loadmodule);
	$self->add_command($last_loadmodule,
			   \&_insert_directive_after,
	           q{LoadModule macro_module lib64/httpd/modules/mod_macro.so});
	$need_macro_module = 0;
	
	$last_loadmodule->fixup_lines($app->filename => 1);
    }

    if (!$letsencrypt_macro_loaded && !$need_macro_module) {
	if ($stop_search) {
	    debug(3, "Will insert \"$include_text\" before $stop_search");
	    $self->add_command($stop_search, \&_insert_directive_before,
			       $include_text);
	} else {
	    debug(3, "Will insert \"$include_text\" after $last_loadmodule");
	    $self->add_command($last_loadmodule, \&_insert_directive_after,
			       $include_text);
        }	    
    }

    $self->run_commands;
}

sub add_command {
    my ($self, $locus, $command, $text) = @_;
    my $file = ($locus->filenames)[0];
    my $line = ($locus->filelines($file))[0];

    push @{$self->{_edits}{$file}}, { line => $line, command => $command, text => $text };
}

sub run_commands {
    my ($self) = @_;
    foreach my $file (keys %{$self->{_edits}}) {
	$self->run_commands_for_file($file);
    }
    $self->apache_modules(undef);
}

sub run_commands_for_file {
    my ($self, $file) = @_;
    my @commands = sort { $a->{line} <=> $b->{line} } @{$self->{_edits}{$file}};

    my $app = new Apache::Config::Preproc(
        $file,
	'-no-comment-grouping',
        -expand => [ 'locus' ])
	or do {
	    error("can't parse apache configuration file $file: $Apache::Admin::Config::ERROR");
	    return;
    };

    foreach my $node ($app->select) {
	last if (!@commands);
	my $line = ($node->locus->filelines(($node->locus->filenames)[0]))[0];
	if ($commands[0]->{line} == $line) {
	    my $cmd = shift @commands;
	    $self->${\ $cmd->{command} }($app, $node, $cmd->{text});
	}
    }

    if (@commands) {
	error((0+@commands) . " left unmatched in edit queue for file $file");
	error("$file left unchanged");
    } else {
	my $backup_name = backup_copy($app->filename, error => \my $error);
	if ($backup_name) {
	    debug(1, "modifying ".$app->filename."; prior version saved in $backup_name");
	} elsif ($error) {
	    error("can't backup ".$app->filename.": $error");
	    error("file left unchanged");
	    return;
	}
	$app->save;
    }
}

sub _replace_directive_at {
    my ($self, $app, $node, $text) = @_;
    $self->_insert_directive_after($app, $node, $text);
    $node->delete;
}

sub _insert_directive_after {
    my ($self, $app, $node, $text) = @_;
    my ($name, $value) = split /\s+/, $text, 2;
    $app->add('directive', $name, $value, -after => $node);
}

sub _insert_directive_before {
    my ($self, $app, $node, $text) = @_;
    my ($name, $value) = split /\s+/, $text, 2;
    $app->add('directive', $name, $value, -before => $node);
}


1;

	    
