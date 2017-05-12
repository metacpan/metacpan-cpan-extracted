package Catalyst::Helper::Model::Jifty::DBI;

use strict;
use warnings;
use Carp;
use FindBin;
use File::Spec;
use File::Basename;

=head1 NAME

Catalyst::Helper::Model::Jifty::DBI

=head1 SYNOPSIS

  # to create a Catalyst::Model::Jifty::DBI class
  script/app_create.pl model ModelName Jifty::DBI

  # or, if you really want to hard-code your configuration
  script/app_create.pl model ModelName Jifty::DBI Schema::Base database test.db ...

  # to create a JDBI::Record/Collection classes under the Model
  script/create.pl model ModelName::RecordName Jifty::DBI

=head1 BACKWARD INCOMPATIBILITY

Current version of Catalyst::(Helper::)Model::Jifty::DBI was once called Catalyst::(Helper::)Model::JDBI::Schemas, which then replaced the original version written by Marcus Ramberg, by the request of Matt S. Trout (Catalyst Core team) to avoid future confusion. I wonder if anyone used the previous one, but note that APIs have been revamped and backward incompatible since 0.03.

=head1 DESCRIPTION

This helper helps you to create a C::M::Jifty::DBI Model class, and optionally, Jifty::DBI::Record/Collection classes under the Model.

Model class will be created when you run it for the first time. Specify your CatalystApp::Model::Name's basename ("Name" for this case), then, this helper's name (Jifty::DBI).

If you really want to specify schema_base for the model (which is equal to the Model class by default), append that Schema::Base::Name, and the key/value pairs of connect_info hash, too. However, I recommend to use ConfigLoader to avoid hard-coded configuration.

When you set up a Model class, you can create Record/Collection classes. Specify ModelName::RecordName (or Schema::Base::Name), and helper's name. Note that Collection class is created automatically. You don't need to (actually, you shouldn't) specify Collection class name, which is confusing.

=head1 METHODS

=head2 mk_compclass

creates actual Model/Record/Collection classes.

=cut

sub mk_compclass {
  my $self   = shift;
  my $helper = shift;

  my $class = $helper->{class};
  my ($parent) = $class =~ /^(.+)::\w+$/;

  my $parent_pm = dirname( $parent ).'.pm';

  if ( -f $parent_pm && $parent !~ /::M(?:odel)$/i ) {
    # probably this is a subclass, ie. record/collection class

    my $record_file = $helper->{file};

    croak "Probably you are going to create a Record class, ".
          "but your Record class has 'Collection' in the name. ".
          "It's confusing. Please use other name."
          if $record_file =~ /Collection\.pm$/i;

    $helper->render_file( 'recordclass', $record_file );

    my $collection_file = $record_file;
       $collection_file =~ s/\.pm$/Collection.pm/;

    $helper->render_file( 'collectionclass', $collection_file );
  }
  else {
    # this should be the main model class

    $helper->{schema_base} = shift || $helper->{class};

    my %connect_info = ( @_ && ( @_ % 2 ) == 0 ) ? @_ : ();

    $connect_info{database} ||= lc $helper->{prefix}.'.db';
    $connect_info{driver}   ||= 'SQLite';
    $connect_info{host}     ||= 'localhost';

    $helper->{connect_info} = \%connect_info;

    $helper->render_file( 'schemaclass', $helper->{file} );
  }
}

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__schemaclass__
package [% class %]

use strict;
use warnings;
use base 'Catalyst::Model::Jifty::DBI';

#### You can hard-code your configuration here,
#### but you may want to use ConfigLoader
#### to move configuration into config.yaml.
#
#__PACKAGE__->config({
#    schema_base  => [% schema_base %],
#    connect_info => {
#        database => '[% connect_info.database %]',
#        driver   => '[% connect_info.driver %]',
#        host     => '[% connect_info.host %]',
#        user     => '[% connect_info.user %]',
#        password => '[% connect_info.password %]',
#    },
#
#### You may want to use this instead of above connect_info
#### when you want to use multiple databases.
#
#    databases => [
#        {
#            name => '[% connect_info.database %]',
#            connect_info => {
#                database => '[% connect_info.database %]',
#                driver   => '[% connect_info.driver %]',
#                host     => '[% connect_info.host %]',
#                user     => '[% connect_info.user %]',
#                password => '[% connect_info.password %]',
#        },
#    ],
#});

=head1 NAME

[% class %] - Catalyst Jifty::DBI Model

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

L<Catalyst::Model::Jifty::DBI> Model using schemas under L<[% schema_base %]>.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
__recordclass__
package [% class %];

use strict;
use warnings;
use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {

# write your schema here like this:
#
#   column "user_id" => type is "integer", is mandatory;
#   column "text"    => type is "text";
#
# See Jifty/Jifty::DBI's documents/sources/tests for details.
#
# Note that you don't have to provide primary key,
# which would be created by Jifty::DBI automatically.

};

=head1 NAME

[% class %] - Catalyst JDBI Schema/Record

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

A Record/Schema class for L<Catalyst::Model::Jifty::DBI> Model.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
__collectionclass__
package [% class %]Collection;

use strict;
use warnings;
use base 'Jifty::DBI::Collection';

=head1 NAME

[% class %]Collection - Catalyst JDBI Collection

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

A Collection class for L<Catalyst::Model::Jifty::DBI> Model.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
