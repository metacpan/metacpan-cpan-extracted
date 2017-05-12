=encoding utf8

=head1 NAME

DBIx::Class::Storage::DBI::mysql::backup

=head1 SYNOPSIS
    
    package MyApp::Schema;
    use base qw/DBIx::Class::Schema/;
    
    our $VERSION = 0.001;
    
    __PACKAGE__->load_classes(qw/CD Book DVD/);
    __PACKAGE__->load_components(qw/
        Schema::Versioned
        Storage::DBI::mysql::backup
    /);


=head1 DESCRIPTION

Adds C<backup> method to L<DBIx::Class::Storage::DBI::mysql>.

This plugin enables L<DBIx::Class::Schema::Versioned/backup> when using MySQL.


=head1 FUNCTIONS

=cut

package DBIx::Class::Storage::DBI::mysql::backup;

use strict;
use warnings;

use DBIx::Class::Storage::DBI;
use MySQL::Backup;
use File::Path qw/mkpath/;
use Symbol;

use vars qw( $VERSION );
$VERSION = '0.04';


=head2 backup ( $to_dir )

writes SQL file as L</backup_filename> to $to_dir. returns SQL filename.

=cut

sub _backup {
    my ( $self, $dir ) = @_;
    mkpath([$dir]) unless -d $dir;
    my $filename = $self->backup_filename;
    my $fh = Symbol::gensym();
    open  $fh, ">$dir/$filename";
    print $fh $self->dump;
    close $fh;
    $filename
}


=head2 backup_filename

returns filename of backup I<$DB_NAME-YYYYMMDD-hhmmss.sql>

=cut

sub _backup_filename {
    my $self = shift;
    my $dsn = $self->_dbi_connect_info->[0];
    my $dbname = $1 if($dsn =~ /^dbi:mysql:database=([^;]+)/i);
    unless($dbname) {
        $dbname = $1 if($dsn =~ /^dbi:mysql:dbname=([^;]+)/i);
    }
    unless($dbname) {
        $dbname = $1 if($dsn =~ /^dbi:mysql:([^;]+)/i);
    }
    $self->throw_exception("Cannot determine name of mysql database")
        unless $dbname;
    my @lt = localtime;
    my $filename = sprintf(
        "%s-%04d%02d%02d-%02d%02d%02d.sql",
        $dbname,
        $lt[5]+1900, $lt[4]+1, $lt[3],
        $lt[2], $lt[1]+1, $lt[0],
    );
    $filename
}

=head2 dump

returns dumped SQL

=cut

sub _dump {
    my $self = shift;
    my $mb = MySQL::Backup->new_from_DBH( $self->dbh ,{'USE_REPLACE' => 1, 'SHOW_TABLE_NAMES' => 1});
    $mb->create_structure() . $mb->data_backup()
}

*DBIx::Class::Storage::DBI::dump = \&_dump;
*DBIx::Class::Storage::DBI::backup = \&_backup;
*DBIx::Class::Storage::DBI::backup_filename = \&_backup_filename;


1;
__END__

=head1 SEE ALSO

=over 2

=item * 
L<DBIx::Class::Schema::Versioned>

=item *
L<MySQL::Backup>

=back

=head1 AUTHOR

Atsushi Nagase <ngs@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 Atsushi Nagase <ngs@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

