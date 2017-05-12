## Tests provide for simple coercions from strings
package Class;
use Moose;
with 'DateTimeX::Format';

sub parse_datetime {
	my ( $self, $time, $env ) = @_;
	$env;
}
sub format_datetime { ; }

package main;
use Test::More tests => 5;

my $env = Class->new->parse_datetime( "foobar", { locale => 'en_AU', time_zone => 'America/Chicago' } );
is ( ref($env->{locale}), 'DateTime::Locale::en_AU', 'Coerce from call arg of locale worked' );
is ( ref($env->{time_zone}), 'DateTime::TimeZone::America::Chicago', 'Coerce from call arg of timezone worked' );

eval {
	Class->new->parse_datetime( "foobar", { locale => 'en_AU', time_zone => 'CEST' } );
};
ok ( ! $@, 'CEST is accepted' );

eval {
	Class->new->parse_datetime( "foobar", { locale => 'en_AU', time_zone => 'CST' } );
};
like ( $@, qr/ambigious/i, 'CST is ambigious' );

eval {
	Class->new->parse_datetime( "foobar", { locale => 'en_AU', time_zone => 'XXCST' } );
};
like ( $@, qr/unknown/i, 'XXCST is unknown' );
