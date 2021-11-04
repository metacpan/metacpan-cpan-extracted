package Data::Kramerius::Object;

use strict;
use warnings;

use Mo qw(is required);

our $VERSION = 0.03;

has id => (
	is => 'ro',
	required => 1,
);

has name => (
	is => 'ro',
	required => 1,
);

has url => (
	is => 'ro',
	required => 1,
);

has version => (
	is => 'ro',
	required => 1,
);

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::Kramerius::Object - Data object for kramerius instance.

=head1 SYNOPSIS

 use Data::Kramerius::Object;

 my $obj = Data::Kramerius::Object->new(%params);
 my $id = $obj->id;
 my $name = $obj->name;
 my $url = $obj->url;
 my $version = $obj->version;

=head1 METHODS

=head2 C<new>

 my $obj = Data::Kramerius::Object->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<id>

Id of Kramerius system.
It's required.

=item * C<name>

Name of Kramerius system.
It's required.

=item * C<url>

URL of Kramerius system.
It's required.

=item * C<version>

Version of Kramerius system.
It's required.

=back

=head2 C<id>

 my $id = $obj->id;

Get id of Kramerius system.

Returns string.

=head2 C<name>

 my $name = $obj->name;

Get name of Kramerius system.

Returns string.

=head2 C<url>

 my $url = $obj->url;

Get URL of Kramerius system.

Returns string.

=head2 C<version>

 my $version = $obj->version;

Get version of Kramerius system.

Returns number.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Data::Kramerius::Object;

 my $obj = Data::Kramerius::Object->new(
         'id' => 'foo',
         'name' => 'Foo Kramerius',
         'url' => 'https://foo.example.com',
         'version' => 4,
 );

 # Print out.
 print 'Id: '.$obj->id."\n";
 print 'Name: '.$obj->name."\n";
 print 'URL: '.$obj->url."\n";
 print 'Version: '.$obj->version."\n";

 # Output:
 # Id: foo
 # Name: Foo Kramerius
 # URL: https://foo.example.com
 # Version: 4

=head1 DEPENDENCIES

L<Mo>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Kramerius>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
