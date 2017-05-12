package Astroboy;
use strict;
use Astroboy::AlbumFile;
use Astroboy::AlbumDir;
use Astroboy::Base;
use vars qw($VERSION); $VERSION = sprintf "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)/g;
no strict 'refs';
use LEOCHARRE::Class2;
__PACKAGE__->make_accessor_setget('errstr');
sub new { return __PACKAGE__ }

sub file { 
   my ($self,$_path) = @_;
   my $abs = Cwd::abs_path($_path) or die;
   -f $abs or die;
   ($self->{file}->{$abs} ||= Astroboy::AlbumFile->new( $abs )) or die;
}

sub dir { 
   my ($self,$_path) = @_;
   my $abs = Cwd::abs_path($_path) or die;
   -d $abs or die;
   ($self->{dir}->{$abs} ||= Astroboy::AlbumDir->new( $abs )) 
      or $self->errstr("not album?")
      and return;
}

# make this a singleton

1;

__END__

see Astroboy::API
