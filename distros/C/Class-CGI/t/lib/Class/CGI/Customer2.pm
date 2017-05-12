package Class::CGI::Customer2;

use strict;
use warnings;
use Example::Customer;

sub new {
    my ( $class, $cgi, $param ) = @_;
    my $value = $cgi->raw_param($param);

    if ( defined $value ) {
        unless ( $value && $value =~ /^\d+$/ ) {
            die "Invalid id ($value) for $class";
        }
        return Example::Customer->new($value)
          || die "Could not find customer for ($value)";
    }
    else {
        my $first = $cgi->raw_param('first_name');
        my $last  = $cgi->raw_param('last_name');

        # pretend we validated and untainted here :)
        return Example::Customer->new->first($first)->last($last);
    }
}

1;

