package Apache::SubProcess;

use strict;
use DynaLoader ();
use Exporter ();
*import = \&Exporter::import;

{
    no strict;
    $VERSION = '0.03';
    @ISA = qw(DynaLoader);
    if ($ENV{MOD_PERL}) {
	__PACKAGE__->bootstrap($VERSION);
    }
    @EXPORT_OK = qw(system exec);
}

sub parse_pgm {
    my $list = shift;
    my($pgm, @args) = split /\s+/, shift @$list;
    push @args, @$list if @$list;
    return($pgm, \@args);
}

sub __system {
    my($is_exec, $aref) = @_;
    
    my $r = Apache->request;
    my($pgm, $args) = parse_pgm($aref);
    #warn "__system: $pgm ", (map { "`$_', " } @$args), "\n";
    my $fh = $r->spawn_child(sub {
	my $r = shift;
	$r->filename($pgm);
	$r->args(join '+', @$args) if @$args;
	$r->call_exec;
    });
    $r->send_fd($fh);
    $r->pfclose($fh);
    if ($is_exec) {
	$ENV{PERL_DESTRUCT_LEVEL} = -2;
	Apache::exit(-2);
    }
}

sub system {
    __system(0, \@_);
}

sub exec {
    __system(1, \@_);
}

1;
__END__->
