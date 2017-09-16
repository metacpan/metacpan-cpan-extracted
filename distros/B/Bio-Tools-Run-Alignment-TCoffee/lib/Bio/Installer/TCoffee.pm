package Bio::Installer::TCoffee;
$Bio::Installer::TCoffee::VERSION = '1.7.2';
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
    %DEFAULTS = ( 'ORIGIN_DOWNLOAD_DIR' => 'http://www.tcoffee.org/Packages/',
                  'BIN_FOLDER' => 'bin',
                  'DESTINATION_DOWNLOAD_DIR' => '/tmp',
                  'DESTINATION_INSTALL_DIR' => "$ENV{'HOME'}",
#                  'PACKAGE_NAME' => 'T-COFFEE_distribution_Version_4.45.tar.gz',
                  'PACKAGE_NAME' => 'T-COFFEE_distribution_Version_5.37.tar.gz',
#                  'DIRECTORY_NAME' => 'T-COFFEE_distribution_Version_4.45',
                  'DIRECTORY_NAME' => 'T-COFFEE_distribution_Version_5.37',
                  'ENV_NAME' => 'TCOFFEEDIR',
                );
}



sub get_default {
    my $self = shift;
    my $param = shift;
    return $DEFAULTS{$param};
}



sub install{
   my ($self,@args) = @_;
   my $dir;
   $self->_decompress;
   $self->_execute_tcoffee_install_script;
   $dir = $self->destination_install_dir;
   $self->_remember_env;
}



sub _execute_tcoffee_install_script{
   my ($self,@args) = @_;
   my $call;

   my $destination = $self->destination_install_dir;
   $destination =~ s|/$||;
   $destination .= "/" . $self->directory_name;

   chdir $destination or die "Cant cd to $destination $!\n";
   print "\n\nCompiling now... (this might take a while)\n\n";
   $call = "sh install";
   system("$call") == 0 or die "Error when trying to run install script $?\n";


}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Installer::TCoffee - DESCRIPTION of Object

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

=head2 _execute_tcoffee_install_script

 Title   : _execute_tcoffee_install_script
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

  https://github.com/bioperl/bio-tools-run-alignment-tcoffee/issues

=head1 AUTHOR

Albert Vilella <avilella@gmail.com>

=head1 COPYRIGHT

This software is copyright (c) by Albert Vilella <avilella@gmail.com>.

This software is available under the same terms as the perl 5 programming language system itself.

=cut
