package DBomb::Generator;

=head1 NAME

DBomb::Generator - Provides routines any generator might need.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.4 $';

use Carp::Assert;
use base qw(Exporter);
use Class::MethodMaker
    'new_with_init' => 'new';


our @EXPORT_OK = qw(gen_accessor);

## subroutine -- not a method!
## gen_accessor($pkg, $sub_name)
## gen_accessor($pkg, $sub_name, $attr_name)
sub gen_accessor
{
    my ($pkg, $sub_name, $attr_name) = @_;
    assert(2 <= @_ && @_ <= 3 && defined($pkg) && defined($sub_name), 'valid parameters');
    $attr_name = $sub_name if not defined $attr_name;

    no strict 'refs';
    *{$pkg . "::" . $sub_name} = sub {
        $_[0]->{$attr_name} = $_[1] if @_ > 1;
        $_[0]->{$attr_name}
    };
}


1;
__END__

