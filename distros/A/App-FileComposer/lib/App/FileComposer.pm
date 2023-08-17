package App::FileComposer;

use warnings;
use strict;
use feature 'say';
use Term::ANSIColor qw(:constants);
use Moose;
use Carp qw(croak);

#// Constructor
has 'filename', is => 'rw', isa => 'Str';
has 'origin', is => 'rw', isa => 'Str', default => $ENV{"HOME"} . "/.app-filecomposer";

=head1 NAME

App::FileComposer - Dumps pre defined scripts!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS
Inside your module:

    use App::FileComposer;

    my $foo = App::FileComposer->new(filename => foo.c);
    $foo->load();

    $foo->write();
    ...


=head1 DESCRIPTION

This module is an internal implemantation of a CLI Tool called mkscript
but, if you wish you can use its internal functions as a module in your script..

App::FileComposer looks for Code samples inside some defined directory and use their data
to write new ones. It saves a lot of time from having to write the same initial lines of 
code every time ...
instead you can define your own samples and load whatever is inside them into a new file 


=head1 SUBROUTINES/METHODS


=head1 

=head1 set_filename()

Change the filename defined in the new method, very Useful in case of Bad filename
errors..


=head1 get_filename()

Get the Current filename passed to new...


=head1 set_sourcePath()

If you wish to change the local of the sample files, define here
the default directory is: /home/user/.samples


=head1 get_sourcePath()

Get the Current samples dir


=head1 load()

load the default samples directory, it dies if does not exists

=head1 write() 

Once the file is loaded through load(), you can write..
write() will dump the file in ./  (The current working directory)


=cut




=head1 AUTHOR

Ariel Vieira, C<< <ariel.vieira at yandex.com> >>

=head1 BUGS

github: L<https://github.com/ariDevelops>

Please report any bugs or feature requests to C<bug-app-filecomposer at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-FileComposer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::FileComposer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-FileComposer>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/App-FileComposer>

=item * Search CPAN

L<https://metacpan.org/release/App-FileComposer>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Ariel Vieira.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991


=cut



#// setters & getters

sub set_filename {
	my ($self, $newname) = @_;
	$self->{'filename'} = $newname;
}

sub set_sourcePath {
  my($self, $path) = @_;
  $self->{'origin'} = $path;
}

sub get_filename { 
  my $self = shift;
  return $self->{'filename'};
}

sub get_sourcePath {
  my $self = shift;
  return $self->{'origin'};
}



#// core methods


sub load {
	my $self = shift;
	my $origin = $self->{'origin'};
	my $filename = $self->{'filename'};
		
   ### Block user from supplying bad filenames
   croak BRIGHT_RED
   'Bad Filename attribute FileComposer->new(filename => \'foo.pl\')', RESET ,
   "\n you must supply extensions like: <name.pl>, <name.py>,  <name.sh>\n"
		 unless $self->{'filename'} =~ /^.+(\.\w+)\b/i;
		 

     

	### isolate the extension in $1
	$filename =~ m{^.+(\.[a-z]+)}i; 
	my $extension = $1;
	
	### Search the file we want 
	opendir DIRHANDLE, $origin
	or croak BRIGHT_RED, 
  " The $origin directory does not exist\n".
  "run in Terminal: \$ mkdir $origin or mkscript --reconf", RESET;
		
    
    #// define a flag 
    our $i_found;		
		
          		while(readdir DIRHANDLE)  {
				              	next unless /$extension\b/i; 	

                        #// flag
					              $i_found = $_; # the sample file we want !
	
				              }close(DIRHANDLE);	
			
									
						
						if ($i_found) {		return $i_found;   }
						  else{
						
						      ###stop the code if don't find the extension we want
      						die BRIGHT_RED, 
		      				"No sample file in $origin containing extension $extension \n", 
				      		RESET;
                }
							
}



sub write {
	my ($self, $where) = @_; 
	my $origin = $self->{'origin'};	
	my $filename = $self->{'filename'};
  #// flag

	our $i_found;
	
  #// dies if we have not the file in $i_found
	croak ' 
  The source guidelines were not loaded internally,
  you forgot to load them..
  Set: $obj->load() method in your code before use write()
  ' unless defined $i_found;



   		{

        #// define a temp file
        my $temp = "temp.$$";

        #// copy data in sample file to the temp file 
        #// after that, rename it 
        open INPUT , '<', "$origin/$i_found" 
            or die "error: $! \n";

                  my @load_file_in_mem = <INPUT>;
                  close(INPUT);

        open OUTPUT, '>>', "./$temp" 
            or die "cannot write to $temp, error: $!\n";
          
                  print OUTPUT $_ for @load_file_in_mem;
                  rename $temp, $filename;

          close(OUTPUT);
    
     		}

  
}



1; # End of App::FileComposer
