package Class::PObject::Driver::db_file;

# db_file.pm,v 1.5 2003/11/07 04:43:14 sherzodr Exp

use strict;
#use diagnostics;
use vars ('$VERSION', '@ISA');
use Carp;
use DB_File;
use Class::PObject::Driver::DBM;

@ISA = ('Class::PObject::Driver::DBM');

$VERSION = '2.01';

sub dbh {
    my ($self, $object_name, $props, $lock_type) = @_;

    my $filename = $self->_filename($object_name, $props);
    my ($DB, %dbh, $unlock);
    $unlock = $self->_lock($filename, $lock_type||'r') or return undef;
    unless ( $DB = tie %dbh, "DB_File", $filename, O_RDWR|O_CREAT, 0600 ) {
        $self->errstr("couldn't connect to '$filename': $!");
        return undef
    }

    return ($DB, \%dbh, $unlock)
}




sub drop_datasource {
    my ($self, $object_name, $props) = @_;

    my (undef, $dbh, $unlock) = $self->dbh($object_name, $props, 'w') or return;
    my $filename = $self->_filename($object_name, $props);
    unless ( unlink $filename ) {
        $self->errstr( "couldn't unlink '$filename': $!" );
        return undef
    }
    $unlock->();
    return 1
}





sub _filename {
    my ($self, $object_name, $props) = @_;


    my $dir = $self->_dir($props);
    my $filename = lc $object_name;
    $filename    =~ s/\W+/_/g;

    return File::Spec->catfile($dir, $filename . '.dbm')
}



sub _dir {
    my ($self, $props) = @_;

    my $dir = $props->{datasource} || File::Spec->tmpdir();
    unless ( -e $dir ) {
        require File::Path;
        File::Path::mkpath($dir) or die $!
    }
    return $dir
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Class::PObject::Driver::db_file - DB_File PObject driver

=head1 SYNOPSIS

    use Class::PObject;
    pobject Article => {
        columns => ['id', 'title', 'author', 'content'],
        driver  => 'db_file',
        datasource => './data'
    };

=head1 DESCRIPTION

Class::PObject::Driver::db_file is a direct subclass of
L<Class::PObject::Driver::DBM|Class::PObject::Driver::DBM>.

=head1 METHODS

Class::PObject::Driver::db_file only provides C<dbh()> method

=over 4

=item *

C<dbh($self, $pobject_name, \%properties)> -  returns a reference to a hash tied to a database.

=back

=head1 SEE ALSO

L<Class::PObject::Driver>
L<Class::PObject::Driver::DBM>

=head1 COPYRIGHT AND LICENSE

For author and copyright information refer to Class::PObject's L<online manual|Class::PObject>.

=cut
