package DBICx::Deploy;
use strict;
use warnings;
use Carp;
use File::Spec;

our $VERSION = '0.02';

sub deploy {
    my ($class, $schema_class, $dsn, @args) = @_;
    croak 'need schema' unless $schema_class;
    croak 'need dsn' unless $dsn;

    eval "require $schema_class" or die "Failed to use $schema_class: $@";

    if($dsn =~ /^DBI:/i){
        my $schema = $schema_class->connect($dsn, @args);
        $schema->deploy;
    }
    else {
        # $dsn is a directory
        my $schema = $schema_class->connect;
        _mkdir($dsn);
        @args = qw/MySQL SQLite PostgreSQL/ if !@args;
        $schema->create_ddl_dir(\@args, undef, $dsn);
    }
}

# wtf.  why?
sub _mkdir {
    my $dir = shift;
    my @dirs = File::Spec->splitdir($dir);
    
    my $base = shift @dirs;
    mkdir $base;
    foreach my $d (@dirs){
        $base = File::Spec->catdir($base, $d);
        mkdir $base;
    }
}

1;

__END__

=head1 NAME

DBICx::Deploy - deploy a DBIx::Class schema

=head1 SYNOPSIS

   use DBICx::Deploy;
   DBICx::Deploy->deploy('My::Schema' => 'DBI:SQLite:root/database');

or

   $ dbicdeploy -Ilib My::Schema DBI:SQLite:root/database

=head1 METHODS

=head2 deploy($schema, $dsn, @args)

Loads the DBIC schema C<$schema>, connects to C<$dsn> (with extra args
C<@args> like username, password, and options), and deploys the
schema.  Dies on failure.

If C<$dsn> doesn't start with "DBI", C<deploy> assumes that you want
to write the SQL to generate the schema to a directory called C<$dsn>.
If C<$dsn> doesn't exist, it (and its parents) will be created for
you.

When deploying to SQL files, C<@args> is a list of database engines
you want to generate SQL for.  It defauts to "MySQL", "SQLite", and
"PostgreSQL".  See L<SQL::Translator> for a list of possible engines.

=head1 SEE ALSO

L<dbicdeploy|dbicdeploy>, included with this distribution.

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 CONTRIBUTORS

The following people have contributed code or bug reports:

=over 4

=item Brian Cassidy

=item Andreas Marienborg

=item Pedro Melo

=back

Thanks!

=head1 LICENSE

This program is free software.  You may redistribute it under the same
terms as Perl itself.
