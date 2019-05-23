package TestHelper;
use Test2::V0;
use Carp;

sub import {
    my $caller = caller;
    no strict 'refs';
    *{"${caller}::make_pkg"} = \&make_pkg;
}

my $pkgcounter = 0;
sub make_pkg {
    my ($args) = @_;
    my $requirements = $args->{requires} || [];
    my @parts = map { "Code::Style::Kit::Parts::$_" } @{ $args->{parts} || [] };
    my $options = $args->{options} || [];
    my $body = $args->{body} || '';

    for my $requirement (@{ $requirements }) {
        eval "require $requirement"
            or skip_all "can't test, $requirement missing";
    }

    ++$pkgcounter;

    eval <<"EOKIT" or croak "Can't compile test kit: $@";
package MyKit$pkgcounter;
use parent qw(Code::Style::Kit @parts);
1;
EOKIT
    $INC{"MyKit$pkgcounter.pm"} = __FILE__;

    # ::Common imports 'true', so we don't need the final "1;"
    $body .= "\n1;" unless grep { /::Common$/ } @parts;

    # for the same reason, we can't expect C<eval> to return a true value
    undef $@;
    eval <<"EOTEST";
package TestPkg$pkgcounter;
use MyKit$pkgcounter \@{\$options};

$body;
EOTEST
    croak "Can't compile test package: $@" if $@;

    return "TestPkg$pkgcounter";
}

1;
