package Autodia::Handler::Mason;

require Exporter;

use strict;

use vars qw($VERSION @ISA @EXPORT);
use Autodia::Handler;

@ISA = qw(Autodia::Handler Exporter);

use Autodia::Diagram;
use HTML::Mason;
use Cwd;

=head1 NAME

Autodia::Handler::Mason - Allows Autodia to parse HTML::Mason files

=head1 SYNOPSIS

See L<Autodia> and L<HTML::Mason>.
Use -p to specify the comp_root and -i fetch one or more components, f.e.
./autodia.pl -l Mason -p 'examples/mason' -i 'index.html login.html'
If you need to allow globals, f.e. $c and $l, add -G '$c $l' to the command line

=head1 DESCRIPTION

L<Autodia::Handler> using introspection provided by L<HTML::Mason> to visualize all components used by a request.

=cut

=head1 API
=cut


=head2
_initialise creates the L<HTML::Mason::Interp> instance used for introspection.
=cut
sub _initialise {
  my ($self, $config) = @_;

  my @Globals = split(/\s/, $config->{mason_globals});  
  $self->{MasonInterp} = new HTML::Mason::Interp->new(comp_root => Cwd::abs_path($config->{inputpath}), 
                                                      allow_globals => \@Globals); 
  return $self->SUPER::_initialise($config, @_);
}

=head2
_parse_file walks through the request and initiates the recursion. 
=cut
sub _parse_file {
  my $self     = shift;
  my $componentname = shift;
  my $Diagram  = $self->{Diagram};
  my $comp_root = $self->{Config}->{inputpath};
  $componentname =~ s/^$comp_root//; # strip comp_root
  $componentname = '/'.$componentname unless $componentname =~ /^\//; # add / if neccessary

  # load component for introspection
  my $Component = $self->{MasonInterp}->load($componentname);
  return 0 unless defined $Component;

  $self->_process_component($Component);

  return 1;
}

=head2
_process_component adds a component to the diagram. This is done recursively for the parent and each called component.
=cut
sub _process_component {
  my ($self, $Component) = @_;
  my $Diagram  = $self->{Diagram};

  # we hopefully see some components more than once
  return $self->{ProcessedComponents}{$Component->title()} if exists $self->{ProcessedComponents}{$Component->title()};

  # create new class with name
  my $Class = Autodia::Diagram::Class->new($Component->title());
  # add class to diagram
  $Class = $Diagram->add_class($Class);
  $self->{ProcessedComponents}{$Component->title()} = $Class;

  # process parent
  if(defined $Component->parent()) {
    my $Superclass = $self->_process_component($Component->parent);
  
    my $Relationship = Autodia::Diagram::Inheritance->new($Class, $Superclass);
    # add Relationship to superclass
    $Superclass->add_inheritance($Relationship);
    # add Relationship to class
    $Class->add_inheritance($Relationship);
    # add Relationship to diagram
    $self->{Diagram}->add_inheritance($Relationship);
  }

  # Args are reported as public attributes
  my $Args = $Component->declared_args();
  foreach my $ArgName (sort keys %$Args) {
   
    $Class->add_attribute($self->_build_attribute($ArgName, $Args->{$ArgName}));
  }

  # Methods are reported as public operations
  my $Methods = $Component->methods();
  foreach my $MethodName (sort keys %$Methods) {
        
    my $MethodComponent = $Methods->{$MethodName};
    my $MethodArgs = $MethodComponent->declared_args();
  
    $Class->add_operation({ name => $MethodName, visibility => 0, 
                            Params => [ map { $self->_build_Param($_, $MethodArgs->{$_})  } sort keys %$MethodArgs ] });
  }

  # Subcomponents are reported as private operations
  my $Subcomps = $Component->subcomps();
  foreach my $SubcompName (sort keys %$Subcomps) {
        
    my $SubcompComponent = $Subcomps->{$SubcompName};
    my $SubcompArgs = $SubcompComponent->declared_args();
  
    $Class->add_operation({ name => $SubcompName, visibility => 1, 
                            Params => [ map { $self->_build_Param($_, $SubcompArgs->{$_})  } sort keys %$SubcompArgs ] 
       });
  }

  # Attributes are reported as public operations with a type
  my $Attributes = $Component->attributes();
  foreach my $AttributeName (sort keys %$Attributes) {
        
    $Class->add_operation({ name => $AttributeName, visibility => 0, type => 'scalar',
                            value => $Attributes->{$AttributeName}});
  }


  # Parse source for dependancies. If you have a better way to gather all called components -- let me know.
  # Calls in comments will be found as well. Calls disguised in variables won't be discovered.
  if($Component->is_file_based) {
    open(FH, "<", $Component->source_file);
    my $Source = join('', <FH>);
    close(FH);
    my @ComponentCalls = $Source =~ /comp\(([^,)]+)/g;
    push @ComponentCalls, $Source =~ /<&\|?([^,&]+)/g;

    foreach (@ComponentCalls) {
      s/^['"\s]+|['"\s]+$//g; # trim spaces and quotationmarks
      
      next if /^(PARENT|SELF):/ or exists $Subcomps->{$_}; # dependancies to SELF, parents or subcomponents are obvious
      my $absCall = /^\// ? $_ : $Component->dir_path().'/'.$_ ;
      
      my $compCall = $self->{MasonInterp}->load($absCall);
      unless (defined $compCall) {
        warn "Can't find component: $absCall in file ".$Component->source_file;
        next;
      }
     
      my $callClass = $self->_process_component($compCall);
     
      my $Relationship = Autodia::Diagram::Dependancy->new($Class, $callClass);
      # add Relationship to callClass
      $callClass->add_dependancy($Relationship);
      # add Relationship to class
      $Class->add_dependancy($Relationship);
      # add Relationship to diagram
      $self->{Diagram}->add_dependancy($Relationship);
    }
  }  

  return $Class
}

=head2
helper method to convert the declared_args of components to attributes
=cut
sub _build_attribute {
  my ($self, $ArgName, $ArgValue) = @_;
  my ($TypeSymbol, $PlainName) = unpack('A1A*', $ArgName);
  my %TypeMap = ( '$' => 'scalar', '%' => 'hash', '@' => 'array' );
  my @DiaParams = (visibility => 0);
  if(exists $TypeMap{$TypeSymbol}) {
    push @DiaParams, (name => $PlainName, type => $TypeMap{$TypeSymbol});
  } else {
    push @DiaParams, (name => $TypeSymbol.$PlainName);
  } 
  if( defined $ArgValue and defined $ArgValue->{'default'} ) {
    push @DiaParams, (value => $ArgValue->{'default'});
  }
  return { @DiaParams };
}

=head2
helper method to convert the declared_args of methods and subcomponents to Params
=cut
sub _build_Param {
  my ($self, $ArgName, $ArgValue) = @_;
  my ($TypeSymbol, $PlainName) = unpack('A1A*', $ArgName);
  my %TypeMap = ( '$' => 'scalar', '%' => 'hash', '@' => 'array' );
  my @DiaParams = (Kind => 1);
  if(exists $TypeMap{$TypeSymbol}) {
    push @DiaParams, (Name => $PlainName, Type => $TypeMap{$TypeSymbol});
  } else {
    push @DiaParams, (Name => $TypeSymbol.$PlainName);
  } 
  if( defined $ArgValue and defined $ArgValue->{'default'} ) {
    push @DiaParams, (Value => $ArgValue->{'default'});
  }
  return { @DiaParams };
}


####-----

1;

=head1 AUTHOR

Peter Franke, 2011, autodia_mason@pfranke.de

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut





