package Bio::Installer::PAML;
$Bio::Installer::PAML::VERSION = '1.7.2';
use utf8;
use strict;
use warnings;

use vars qw(@ISA %DEFAULTS);

use Bio::Root::Root;
use Bio::Installer::Generic;

@ISA = qw(Bio::Installer::Generic );

# ABSTRACT: DESCRIPTION of Object
# AUTHOR: Albert Vilella <avilella@gmail.com>
# OWNER: Albert Vilella <avilella@gmail.com>
# LICENSE: Perl_5


BEGIN {
    %DEFAULTS = ( 'ORIGIN_DOWNLOAD_DIR' => 'http://abacus.gene.ucl.ac.uk/software/',
                  'BIN_FOLDER' => 'src',
                  'DESTINATION_DOWNLOAD_DIR' => '/tmp',
                  'DESTINATION_INSTALL_DIR' => "$ENV{'HOME'}",
                  'PACKAGE_NAME' => 'paml4a.tar.gz',
                  'DIRECTORY_NAME' => 'paml4',
                  'ENV_NAME' => 'PAMLDIR',
                );
}



sub get_default {
    my $self = shift;
    my $param = shift;
    return $DEFAULTS{$param};
}



sub install{
   my ($self,@args) = @_;
   $self->_decompress;
   $self->_tweak_paml_makefile;
   $self->_execute_paml_makefile;
   $self->_remember_env;
}



sub _execute_paml_makefile{
   my ($self,@args) = @_;
   my $call;

   my $destination = $self->destination_install_dir . "/" . $self->directory_name . "/src";
   chdir $destination or $self->throw("Cant cd to $destination");
   print "\n\nCompiling now... (this might take a while)\n\n";
   if (($^O =~ /dec_osf|linux|unix|bsd|solaris|darwin/i)) {
       $call = "make";
       system("$call") == 0 or $self->throw("Error when trying to run make");
   } else {
       $self->throw("_execute_paml_makefile not yet implemented in this platform");
   }
}



sub _tweak_paml_makefile{
    my ($self,@args) = @_;
    my $gcc3;
    my $return = qx/gcc -v 2>&1/;
    if ($return =~ /version 3/) {
        $return = `cat /proc/cpuinfo`;
        if( ($return =~ /mmx/) || ($return =~ /3dnow/)) {
            my $destination = $self->destination_install_dir . "/" . $self->directory_name . "/src";
            chdir $destination or $self->throw("Cant cd to $destination");
            my $new = "Makefile";
            open(OLD, "< Makefile.UNIX")         or  $self->throw("can't open Makefile.UNIX");
            open(NEW, "> $new")         or $self->throw("can't open $new");
            while (<OLD>) {
                # change $_, then...
                $_ =~ s/CFLAGS = -O3/\# CFLAGS = -O3/g;
                if( $return =~ /3dnow/ ) {
                    $_ =~ s/#CFLAGS = -march=athlon -mcpu=athlon -O4 -funroll-loops -fomit-frame-pointer -finline-functions/CFLAGS = -march=athlon -mcpu=athlon -O4 -funroll-loops -fomit-frame-pointer -finline-functions/g;
                } elsif( $return =~ /mmx/ ) {
                    $_ =~ s/#CFLAGS = -march=pentiumpro -mcpu=pentiumpro -O4 -funroll-loops -fomit-frame-pointer -finline-functions/CFLAGS = -march=pentiumpro -mcpu=pentiumpro -O4 -funroll-loops -fomit-frame-pointer -finline-functions/g;
                }
                print NEW $_ or $self->throw("can't write $new");
            }
            close(OLD)                  or $self->throw("can't close Makefile.UNIX");
            close(NEW)                  or $self->throw("can't close $new");
        }
    }


}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Installer::PAML - DESCRIPTION of Object

=head1 VERSION

version 1.7.2

=head1 SYNOPSIS

Give standard usage here

=head1 DESCRIPTION

Describe the object here

=head1 METHODS

=head2 get_default

 Title   : get_default
 Usage   :
 Function:
 Example :
 Returns :
 Args    :

=head2 install

 Title   : install
 Usage   : $installer->install();
 Function:
 Example :
 Returns :
 Args    :

=head1 INTERNAL METHODS

=head2 _execute_paml_makefile

 Title   : _execute_paml_makefile
 Usage   :
 Function:
 Example :
 Returns :
 Args    :

=head2 _tweak_paml_makefile

 Title   : _tweak_paml_makefile
 Usage   :
 Function:
 Example :
 Returns :
 Args    :

=head1 FEEDBACK

=head2 Mailing lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org              - General discussion
  http://bioperl.org/Support.html    - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:
I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  https://github.com/bioperl/bio-tools-phylo-paml/issues

=head1 AUTHOR

Albert Vilella <avilella@gmail.com>

=head1 COPYRIGHT

This software is copyright (c) by Albert Vilella <avilella@gmail.com>.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
