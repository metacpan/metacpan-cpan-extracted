package Config::MorePerl;
use 5.012;
use Path::Class;
use Data::Recursive(); # XS code needs xs::merge

our $VERSION = '1.2.3';

XS::Loader::load();

sub process {
    my ($class, $file, $initial_cfg) = @_;
    $file = Path::Class::File->new($file);

    my ($mstash, $nsstash);
    {
        no strict 'refs';
        $mstash = \%{"::"};
        delete $mstash->{'NS::'};
        $nsstash = \%{"NS::"};
    }

    $DB::{disable_profile}() if $DB::{disable_profile} && !$ENV{MP_WRITE_NYTPROF};
    _apply_initial_cfg('', Data::Recursive::clone($initial_cfg)) if $initial_cfg;
    _process_file($file);
    $DB::{enable_profile}() if $DB::{enable_profile} && !$ENV{MP_WRITE_NYTPROF};

    my $ret = {};

    my $cfg = {};
    if(defined $nsstash->{'__CONFIG__'}){
        $cfg = ${$nsstash->{'__CONFIG__'}};
        delete $nsstash->{'__CONFIG__'};
    }
    _get_config($ret, $nsstash, $cfg, '');

    # remove garbage we've created
    delete $mstash->{'NS::'};

    return $ret;
}

sub _apply_initial_cfg {
    my ($ns, $cfg) = @_;
    foreach my $key (keys %$cfg) {
        if (substr($key, -2, 2) eq '::') {
            _apply_initial_cfg($ns.$key, $cfg->{$key});
        } else {
            no strict 'refs';
            *{"NS::$ns$key"} = \$cfg->{$key};
        }
    }
}

sub _process_file {
    my ($file, $ns) = @_;
    my $content = $file->slurp;

    my $curdir = $file->dir;

    $content =~ s/^[^\S\r\n]*#(namespace|namespace-abs|include)(?:[^\S\r\n]+(.+))?$/_process_directive($curdir, $ns, $1, $2)/gme;

    my $pkg = $ns ? "NS::$ns" : "NS";
    $content = "package $pkg; sub { $content;\n }";
    my $ok;
    {
        no strict;
        enable_op_tracking();
        my $sub = eval $content;
        disable_op_tracking();
        $ok = eval { $sub->(); 1 } if $sub;
    }
    unless ($ok) {
        my $err = $@;
        die $err if $err =~ /Error-prone code/;
        $err =~ s/Config::MorePerl: //g unless ref $err;
        die "Config::MorePerl: error while processing config $file: $err\n".
            "================ Error-prone code ================\n".
            _content_linno($content).
            "==================================================";
    }

    return;
}

sub _process_directive {
    my ($curdir, $ns, $directive, $rest) = @_;
    $rest //= '';
    $rest =~ s/\s+$//;
    if (index($directive, 'namespace') == 0) {
        $ns = '' if $directive eq 'namespace-abs';
        my $pkg = $ns ? "NS::$ns" : 'NS';
        $pkg .= "::$1" if $rest =~ /\s*(\S+)/;
        return "package $pkg;";
    }
    elsif ($directive eq 'include') {
        return "Config::MorePerl::_INCLUDE('$curdir', __PACKAGE__, $rest);";
    }
}

sub _INCLUDE {
    my ($dir, $curpkg, $file) = @_;
    $dir = $dir && Path::Class::Dir->new($dir);
    $file = Path::Class::File->new($file);
    my $ns = '';
    if ($curpkg ne 'NS') {
        $ns = $curpkg;
        substr($ns, 0, 4, ''); # remove /^NS::/
    }
    
    $file = $dir->file($file) if $dir && !$file->is_absolute;
    
    if (index($file, '*') >= 0) {
        _process_file(Path::Class::File->new($_), $ns) for glob($file);
    } else {
        _process_file($file, $ns);
    }
}

sub _get_config {
    my ($dest, $stash, $config, $ns) = @_;
    my @ns_list;

    my $assign_proc;
    $assign_proc = $config->{assign_proc} if defined $config->{assign_proc};
    foreach my $key (keys %$stash) {
        next if $key eq 'BEGIN' or $key eq 'DESTROY' or $key eq 'AUTOLOAD' or index($key, '__ANON__') == 0;
        if (substr($key, -2, 2) eq '::') {
            push @ns_list, $key;
            next;
        }
        my $glob = $stash->{$key} or next;
        next if !defined $$glob and defined *$glob{CODE};
        if(defined $assign_proc){
            $dest->{$key} = undef;
            $assign_proc->($dest->{$key}, $$glob);
        } else {
            $dest->{$key} = $$glob;
        }
    }

    foreach my $subns (@ns_list) {
        my $substash = \%{$stash->{$subns}};
        substr($subns, -2, 2, '');
        my $subns_full = $ns ? "${ns}::$subns" : $subns;
        if (exists $dest->{$subns}) {
            die "Config::MorePerl: conflict between variable '$subns' in namespace '$ns' and a namespace '$subns_full'. ".
                "You shouldn't have variables that overlap with namespaces as they would merge into the same hash.\n";
        }
        _get_config($dest->{$subns} = {}, $substash, $config, $subns_full);
    }
}

sub _content_linno {
    my $content = shift;
    my $i = 0;
    $content =~ s/^(.*)$/$i++; "$i: $1"/mge;
    return $content;
}

1;
