package Bio::AssemblyImprovement::Scaffold::SSpace::TempDirectoryRole;
# ABSTRACT: Role for handling temp directories



use Moose::Role;
use Cwd;
use File::Temp;

has '_temp_directory_obj' => ( is => 'ro', isa => 'File::Temp::Dir', lazy     => 1, builder => '_build__temp_directory_obj' );
has '_temp_directory'     => ( is => 'ro', isa => 'Str', lazy     => 1, builder => '_build__temp_directory' );
has 'debug'               => ( is => 'ro', isa => 'Bool', default => 0);

sub _build__temp_directory_obj {
    my ($self) = @_;
    
    my $cleanup = 1;
    $cleanup = 0 if($self->debug == 1);
    File::Temp->newdir( CLEANUP => $cleanup , DIR => getcwd() );
}

sub _build__temp_directory {
    my ($self) = @_;
    $self->_temp_directory_obj->dirname();
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::AssemblyImprovement::Scaffold::SSpace::TempDirectoryRole - Role for handling temp directories

=head1 VERSION

version 1.160490

=head1 SYNOPSIS

Role for handling temp directories.

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
