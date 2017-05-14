package Bio::Genex::Fkey;
use strict;
use vars qw(@ISA @METHODS %EXPORT_TAGS);
use Carp;

require Exporter;
@ISA = qw(Exporter);
@METHODS = qw(table_name fkey_type pkey_name fkey_name);

# Fkey constants
use constant FKEY_OTM         => 'ONE_TO_MANY';
use constant FKEY_OTM_LT      => 'ONE_TO_MANY_LT';
use constant FKEY_OTM_LINK    => 'ONE_TO_MANY_LINK';
use constant FKEY_LINK        => 'LINKING_TABLE';
use constant FKEY_FKEY        => 'FKEY';
use constant FKEY_LT          => 'LOOKUP_TABLE';
use constant FKEY_MTO         => 'MANY_TO_ONE';

# and their object oriented counterparts
use constant FKEY_OTM_OO      => 'ONE_TO_MANY_OO';
use constant FKEY_OTM_LT_OO   => 'ONE_TO_MANY_LT_OO';
use constant FKEY_OTM_LINK_OO => 'ONE_TO_MANY_LINK_OO';
use constant FKEY_LINK_OO     => 'LINKING_TABLE_OO';
use constant FKEY_FKEY_OO     => 'FKEY_OO';
use constant FKEY_LT_OO       => 'LOOKUP_TABLE_OO';
use constant FKEY_MTO_OO      => 'MANY_TO_ONE_OO';

# this enables us to export the fkey constants to other modules
# we have to be careful to quote the names, so that they are not treated as 
# a function call, which would replace them with the constant to which they refer. 
%EXPORT_TAGS = (FKEY => ['FKEY_OTM_OO',
			 'FKEY_OTM_LT_OO',
			 'FKEY_OTM_LINK_OO',
			 'FKEY_LINK_OO',
			 'FKEY_MTO_OO',
			 'FKEY_LT_OO',
			 'FKEY_FKEY_OO',
			 'FKEY_OTM',
			 'FKEY_OTM_LT',
			 'FKEY_OTM_LINK',
			 'FKEY_LINK',
			 'FKEY_MTO',
			 'FKEY_LT',
			 'FKEY_FKEY',
			]);
Exporter::export_ok_tags('FKEY');

=head1 NAME

Bio::Genex::Fkey - Perl extension for representing Database Foreign Keys

=head1 SYNOPSIS

  use Bio::Genex::Fkey qw(:FKEY);

  $fkey_obj = Bio::Genex::Fkey->new('table_name'=>$file,
			       'pkey_name'=>$column_name,
			       'fkey_type'=> FKEY_OTM_LT);

=head1 DESCRIPTION

This is a utility class for storing information about foreign keys in
the GeneX DB.

=head1 METHODS

=cut

sub new {
  my ($class,%args) = @_;
  
  # this method serves double duty as a copy constructor
  my $copy;
  if (ref($class)) {
    $copy = $class;
    $class = ref($copy);
  }
  my $self = {};
  bless $self, $class;
  
  if (defined $copy) {
    # copy the existing object
    foreach my $method (qw/table_name
			fkey_type
			pkey_name
			fkey_name/) {
      no strict 'refs';
      $self->$method($copy->$method());
    }
  } else {
    foreach my $key (keys %args) {
      # ensure all keys are valid methods
      die "$ {class}::new: bad argument: $key" unless
	grep {$_ eq $key} @METHODS;
      no strict 'refs';
      $self->$key($args{$key});
    }
  }
  return $self;
}

sub table_name {
  my ($self) = shift;
  $self->{'table_name'} = shift if scalar @_;
  return $self->{'table_name'};
}

sub fkey_type {
  my ($self) = shift;
  $self->{'fkey_type'} = shift if scalar @_;
  return $self->{'fkey_type'};
}

sub pkey_name {
  my ($self) = shift;
  $self->{'pkey_name'} = shift if scalar @_;
  return $self->{'pkey_name'};
}

sub fkey_name {
  my ($self) = shift;
  $self->{'fkey_name'} = shift if scalar @_;
  return $self->{'fkey_name'};
}

# package Bio::Genex::Fkey::FKEY;
# use strict;
# use vars qw(@ISA);
# use Carp;
# 
# require Exporter;
# @ISA = qw(Exporter);
# 
# package Bio::Genex::Fkey::LINK;
# use strict;
# use vars qw(@ISA);
# use Carp;
# 
# require Exporter;
# @ISA = qw(Exporter);
# 
# package Bio::Genex::Fkey::OTM_LINK;
# use strict;
# use vars qw(@ISA);
# use Carp;
# 
# require Exporter;
# @ISA = qw(Exporter);
# 
# package Bio::Genex::Fkey::OTM_LT;
# use strict;
# use vars qw(@ISA);
# use Carp;
# 
# require Exporter;
# @ISA = qw(Exporter);
# 
# package Bio::Genex::Fkey::MTO;
# use strict;
# use vars qw(@ISA);
# use Carp;
# 
# require Exporter;
# @ISA = qw(Exporter);
# 
# package Bio::Genex::Fkey::OTM;
# use strict;
# use vars qw(@ISA);
# use Carp;
# 
# require Exporter;
# @ISA = qw(Exporter);


1;
