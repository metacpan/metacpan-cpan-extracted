package Bing::Search::Role::WebRequest::FileType;
use Moose::Role;
use Carp;

requires 'build_request';
requires 'params';


has 'Web_FileType' => (
   is => 'rw',
   isa => 'Str',
   predicate => 'has_Web_FileType'
);

has '_supported_Web_FileTypes' => (
   is => 'rw',
   isa => 'HashRef',
   default => sub { 
       return { map { $_ => 1 } qw( DOC DWF FEED HTM HTML PDF PPT PS RTF TEXT TXT XLS ) };
   }
);

around 'Web_FileType' => sub { 
   my $next = shift;
   my( $self, $param ) = @_;
   my $supported = $self->_supported_Web_FileTypes;
   if( $param ) {    
      if( exists $supported->{$param} ) { 
         $self->$next( $param );
      } else { 
         carp "Unsupported file type $param -- ignoring.";
      }
   } else { 
      $self->$next();
   }

};

before 'build_request' => sub { 
   my $self = shift;
   if( $self->has_Web_FileType ) { 
      my $hash = $self->params;
      $hash->{'Web.FileType'} = $self->Web_FileType;
      $self->params( $hash );
   }
};

1;
