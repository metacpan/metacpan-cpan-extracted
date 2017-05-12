package Catalyst::Plugin::CodeEval;

use strict;
use warnings;
use PadWalker qw(peek_my);

our $VERSION = '0.012';

my($Revision) = '$Id: CodeEval.pm,v 1.6 2006/02/14 09:40:47 Sho Exp $';


=head1 NAME

Catalyst::Plugin::CodeEval - Module for huge Catalyst application development.

=head1 SYNOPSIS

  # in your catalyst application.
  use Catalyst 'CodeEval';

  $c->code_eval('perl_script.pl');

=cut

=head1

  # create file in your catalyst application directory.

  # $c->config->home . /code_eval/perl_script.pl

  $c->log->debug('bar bar bar');
  $c->log->debug('$c->req->base->host : '.$c->req->base->host);
  1;

=head1 DESCRIPTION

perl script file is executed by using eval.
happiness visits when starting of your application is very slow.

=head1 METHODS

=head2 code_eval

perl script file is executed by using eval.

=cut

sub code_eval {
    my $c = shift;
    my $CodeEval_code_eval_file = shift;
    my $CodeEval_uplevel_variable = peek_my(1);
    my $CodeEval_code_sourcecode;
    eval {
	$CodeEval_code_sourcecode = $c->read_code($CodeEval_code_eval_file);
    };
    if($@) {
	$c->log->debug("+++++ CodeEval : load script file error : \n$@");
	return 1;
    }

    my $CodeEval_variable_code;
    foreach my $key (grep($_ ne '$c', keys(%{$CodeEval_uplevel_variable}))) {
	if($key =~ /^\$/) {
	    $CodeEval_variable_code .= "my $key = \${\$CodeEval_uplevel_variable->{'$key'}};\n";
	} elsif($key =~ /^\@/) {
	    $CodeEval_variable_code .= "my $key = \@{\$CodeEval_uplevel_variable->{'$key'}};\n";
	} elsif($key =~ /^\%/) {
	    $CodeEval_variable_code .= "my $key = \%{\$CodeEval_uplevel_variable->{'$key'}};\n";
	} else {
	    $CodeEval_variable_code .= "my $key = \$CodeEval_uplevel_variable->{'$key'};\n";
	}
    }

#    $c->log->debug("++++ CodeEval : eval this code +++++\n".$CodeEval_variable_code . $CodeEval_code_sourcecode);
    my $rt = eval($CodeEval_variable_code . $CodeEval_code_sourcecode);
    if($@) {
	$c->log->debug("+++++ CodeEval : execute error : \n$@");
    } else {
	$c->log->debug("+++++ CodeEval : execute end : return $rt +++++");
    }
    return $rt;
}

=head2 read_code

read file

=cut

sub read_code {
    my $c = shift;
    my $file = shift;
    
    my $script_file = $c->path_to('code_eval',$file);
    $c->log->debug("+++++ CodeEval : load script file ($script_file) +++++");

    open(CODEFILE, $script_file) or die "can not open $script_file\n";
    my $code = join("",<CODEFILE>);
    close(CODEFILE);
    return $code
}

=head1 SEE ALSO

L<Catalyst> L<PadWalker>

=head1 AUTHOR

Shota Takayama, C<shot[atmark]bindstorm.jp>

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
