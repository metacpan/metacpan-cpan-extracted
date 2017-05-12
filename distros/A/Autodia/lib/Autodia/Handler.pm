################################################################
# AutoDIA - Automatic Dia XML.   (C)Copyright 2001 A Trevena   #
#                                                              #
# AutoDIA comes with ABSOLUTELY NO WARRANTY; see COPYING file  #
# This is free software, and you are welcome to redistribute   #
# it under certain conditions; see COPYING file for details    #
################################################################
package Autodia::Handler;

use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT);

@ISA = qw(Exporter);

use Autodia::Diagram;

#---------------------------------------------------------------

#####################
# Constructor Methods

sub new
{
  my $class  = shift();
  my $self   = {};
  my $config = shift;

  bless ($self, ref($class) || $class);
  $self->_initialise($config);

  return $self;
}

#------------------------------------------------------------------------
# Access Methods

=head2 process

parse file(s), takes hashref of configuration, returns no of files processed

=cut 

sub process {
  my $self = shift;
  my %config = %{$self->{Config}};

  my $processed_files = 0;
  my ($ignore_path) = grep { warn "$_" && $config{inputpath} eq $_.'/' } @{$config{directory}};
  foreach my $filename (@{$config{filenames}}) {
    my $current_file = ($ignore_path) ? $filename : $config{inputpath} . $filename ;
    $current_file =~ s|\/+|/|g;
    print "opening $current_file\n" unless ( $config{silent} );
    $self->_reset() if ($config{singlefile});
    $self->_parse_file($current_file)
      or warn "no such file / database - $current_file \n";
    $self->output($current_file) if ($config{singlefile});
    $processed_files++;
  }
  return $processed_files;
}

sub skip {
  my ($self,$object_name) = @_;
  my $skip = 0;
  my $skip_list = $self->{Config}{skip_patterns};
  if (ref $skip_list) {
    foreach my $pattern (@$skip_list) {
      chomp($pattern);
      if ($object_name =~ m/$pattern/) {
	warn "skipping $object_name : matches $pattern\n" unless ($self->{_config}{silent});
	$skip = 1;
	last;
      }
    }
  }
  return $skip;
}


sub output
  {
    my $self    = shift;
    my $alternative_filename = shift;
    my $Diagram = $self->{Diagram};
    my %config = %{$self->{Config}};

    if (defined $alternative_filename ) { 
	foreach my $dir (@{$config{'directory'}}) {
	    $alternative_filename =~ s|^$dir||g;
	}
	$alternative_filename =~ s|\/|-|g;
	$alternative_filename =~ s|^-||;
    }
    

    $Diagram->remove_duplicates;

    # export output
    my $success = 0;
    OUTPUT_TYPE: {
	    if ($config{graphviz}) {
		$self->{Config}{outputfile} = "$alternative_filename.png" if ($config{singlefile});
		$success = $Diagram->export_graphviz(\%config);
		last;
	    }

	    if ($config{springgraph}) {
		$self->{Config}{outputfile} = "$alternative_filename.png" if ($config{singlefile});
		$success = $Diagram->export_springgraph(\%config);
		last;
	    }

	    if ($config{vcg}) {
		$self->{Config}{outputfile} = "$alternative_filename.ps" if ($config{singlefile});
		$success = $Diagram->export_vcg(\%config);
		last;
	    }

	    # default to XML output
	    $self->{Config}{outputfile} = "$alternative_filename.xml" if ($config{singlefile});
	    $success = $Diagram->export_xml(\%config);
	} # end of OUTPUT_TYPE;
    if ($success) {
	warn "written outfile : $config{outputfile} successfully \n";
    } else {
	warn "nothing to output using $config{language} handler - are you sure you set the language correctly ?\n";
    }
    return 1;
  }

#-----------------------------------------------------------------------------
# Internal Methods

sub _initialise
{
  my $self    = shift;
  my $config_ref = shift;
  my $Diagram = Autodia::Diagram->new($config_ref);

  $self->{Config}  = $config_ref || ();
  $self->{Diagram} = $Diagram;

  return 1;
}

sub _reset {
  my $self = shift;
  my $config_ref = $self->{Config};
  my $Diagram = Autodia::Diagram->new($config_ref);
  $self->{Diagram} = $Diagram;
  return 1;
}

sub _error_file
  {
    my $self          = shift;

    $self->{file_open_error} = 1;

    print "Handler.pm : _error_file : error opening file $! \n";
    #$error_message\n";

    return 1;
  }

sub _parse
  {
    print "parsing file \n";
    return;
  }

sub _parse_file {
  my $self     = shift();
  my $filename = shift();
  my %config   = %{$self->{Config}};
  my $infile   = (defined $config{inputpath}) ?
    $config{inputpath} . $filename : $filename ;

  $self->{file_open_error} = 0;

  open (INFILE, "<$infile") or $self->_error_file();

  if ($self->{file_open_error} == 1) {
    warn " couldn't open file $infile \n";
    print "skipping $infile..\n";
    return 0;
  }

  $self->_parse (\*INFILE,$filename);

  close INFILE;

  return 1;
}

1;

###############################################################################

=head1 NAME

Handler.pm - generic language handler superclass

=head1 CONSTRUCTION METHOD

Not actually used but subclassed ie HandlerPerl or HandlerC as below:

my $handler = HandlerPerl->New(\%Config);

=cut
