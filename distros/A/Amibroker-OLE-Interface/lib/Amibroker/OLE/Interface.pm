package Amibroker::OLE::Interface;

use 5.006;
use strict;
use warnings;
use Win32::OLE;
use Win32;
use Carp;

=head1 NAME

Amibroker::OLE::Interface - A Simple Perl interface to OLE Automation framework of Amibroker Software.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Amibroker::OLE::Interface;
    my $obj = Amibroker::OLE::Interface->new( { verbose => 1, 
                                                dbpath => "C:/amibroker/dbpath"
                                            } );
    $obj->start_amibroker_engine();
    $obj->run_analysis( { action => 2,
                          symbol => 'NIFTY-I', 
                          apx_file => 'C:/amibroker/apx/path/nifty.apx', 
                          result_file => 'C:/amibroker/result/path/report.csv'} );
    $obj->shutdown_amibroker_engine();

=head1 DESCRIPTION

Amibroker is one of the most used Automated trading and charting software in the world. 
Visit Amibroker website for information : L<https://www.amibroker.com/> 
Amibroker has provided OLE Automation framework, to interact with Amibroker engine from external scripts/programs.
You can refer to the AmiBroker's OLE Automation Object Model guide: L<https://www.amibroker.com/guide/objects.html>

This module will help programmers who use Amibroker to access the objects easily in perl. 

=head1 PREREQUISITE

Prerequisite to use this module : You need to have Amibroker v.5 and above (32-bit or 64-bit) installed in your system.

=head2 new()

Constructor to create the object for interacting with Amibroker engine.
The new() class method starts a new instance of an Amibroker OLE Interface object. It returns a reference to this object or undef if the creation failed.

    Eg: Amibroker::OLE::Interface->new()

=over 1

=item B<Parameters to the constructor>

=back

=over 2

=item * Verbose is optional

=item * dbpath  is compulsory - dbpath should be valid Amibroker database path.
For how to create database, please check here : L<https://www.amibroker.com/guide/w_dbsettings.html>

    Code Example
	$obj = Amibroker::OLE::Interface->new( verbose => 1, dbpath => "C:/amibroker/dbpath");

=back

=cut

sub new {
    my @list  = @_;
    my $class = shift @list;
    push @list, {} unless @list and _is_arg( $list[-1] );
    my $self = _check_valid_args(@list);
    croak("No Database path supplied to Amibroker : $!\n")
      unless $self->{dbpath};
    croak("Invalid Database path to Amibroker : $!\n")
      unless -d $self->{dbpath};

    bless $self, $class if defined $self;
    return $self;
}

=head2 start_amibroker_engine()

Starts the Amibroker Engine and Loads the database

Code Example

    $obj->start_amibroker_engine();

=cut

sub start_amibroker_engine {
    my $self = shift;
    $self->{broker} = Win32::OLE->new('Broker.Application')
      or croak("Can't load Broker.Application : $!\n");
    print "Amibroker Started\n" if $self->{verbose};
    $self->{broker}->LoadDatabase( $self->{dbpath} )
      or croak(
        "Can't load Database, seems like the format is not supported: $!\n");
    print "Database loaded to Amibroker\n" if $self->{verbose};
    return 1;
}

=head2 run_analysis()

You can run various analysis based on the action supplied.
But before that you need to pass APX file, 

APX file is an important file to Amibroker engine. It is like the rule book to the amibroker.
The analysis project file (.apx extension) is human-readable self-explanatory XML-format file that can be written/edited/modified from any language / any text editor. 
APX file includes all settings and formula needed in single file that is required to run analysis. 
APX file instructs what the amibroker engine has to do.

NOTE: Be very careful in creating the apx file.

You can either manually create the apx file or by automatically by a script.
There should be no errors in the content of APX file, else the analysis of the Amibroker fails.

How to create apx file manually:

=over 3

=item * Open Amibroker -> Analysis window -> Settings

=item * Edit settings as per your requirement

=item * Menu-> File-> Save_AS -> select (.apx extenstion)

For more infor on apx file, check this forum : L<http://amibrokerforum.proboards.com/thread/57/analysis-project-files-apx>

    $obj->run_analysis( action => 2 ) method allows to run asynchronously scan/explorations/backtest/optimizations.
    Action parameter can be one of the following values:
    0 : Scan
    1 : Exploration
    2 : Portfolio Backtest
    3 : Individual Backtest
    4 : Portfolio Optimization 
    5 : Individual Optimization (supported starting from v5.69)
    6 : Walk Forward Test

Symbol would be appended with '-I' => for current month contract future or '-II' for next month contract future
Eg: for Nifty, Symbol would be 'Nifty-I'.
This is just an example, you should check your database for the exact symbol name. 
If the Symbol passed to this function is not present in your amibroker database, then the analysis is bound to fail.

result_file is the path where you want to dump the result of the Amibroker analysis.
result_file file should NOT be created manually, it will be created automatically by the Amibroker engine when the analysis runs. You have to just pass the filename with the path.

=back

=over 1

=item B<parameters to run_analysis method>

=back

=over 4

=item * action      is compulsory

=item * symbol      is compulsory

=item * apx_file    is compulsory

=item * result_file is Optional - Default will be stored in C:/result.csv

Code Example

    $obj->run_analysis( { action => 2, 
						  symbol => 'NIFTY-I', 
                          apx_file => "C:/amibroker/apx/path/nifty.apx", 
                          result_file => "C:/amibroker/result/path/report.csv" 
					   } ); 

=back

=cut

sub run_analysis {
    my @list = @_;
    my $self = shift @list;
    my $args = _check_valid_args(@list);
    croak("Invalid apx file : $!\n") unless -e $args->{apx_file};
    $args->{apx_file} =~ s/\//\\\\/g;
    $args->{result_file} =~ s/\//\\\\/g if ( $args->{result_file} );
    $self->{broker}->ActiveDocument->{Name} = $args->{symbol};
    my $analysis = $self->{broker}->AnalysisDocs->Open( $args->{apx_file} )
      or croak("Could'nt open analysis in Amibroker: $!\n");

    if ($analysis) {
        $analysis->Run( $args->{action} );

        # Keep waiting till Amibroker completes - There is no end to wait.
        Win32::Sleep(500) while ( $analysis->IsBusy );
        $analysis->Export( $args->{result_file} );
        $analysis->Close();
    }
    return 1;
}

=head2 shutdown_amibroker_engine()

Shuts down Amibroker engine.

Code Example

	$obj->shutdown_amibroker_engine();

=cut

sub shutdown_amibroker_engine {
    my $self = shift;
    print "Shutting down Amibroker Engine\n" if $self->{verbose};
    $self->{broker}->Quit();
    return 1;
}

#
# Supporting functions to the above useful methods
#
sub _is_arg {
    my ($arg) = @_;
    return ( ref $arg eq 'HASH' );
}

sub _check_valid_args {
    my @list = @_;
    my %args_permitted = map { $_ => 1 } (
        qw|
          dbpath
          verbose
          broker
          symbol
          apx_file
          action
          result_file
          |
    );
    my @bad_args = ();
    my $arg      = pop @list;
    for my $k ( sort keys %{$arg} ) {
        push @bad_args, $k unless $args_permitted{$k};
    }
    croak("Unrecognized option(s) passed to Amibroker OLE: @bad_args")
      if @bad_args;
    return $arg;
}

=head1 AUTHOR

Babu Prasad HP, C<< <bprasad at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-amibroker-ole-interface at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Amibroker-OLE-Interface>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Amibroker::OLE::Interface


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Amibroker-OLE-Interface>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Amibroker-OLE-Interface>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Amibroker-OLE-Interface>

=item * Search CPAN

L<http://search.cpan.org/dist/Amibroker-OLE-Interface/>

=back


=head1 ACKNOWLEDGEMENTS

I would like to thank Mr.Pannag M for supporting me in writing this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Babu Prasad HP.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Amibroker::OLE::Interface
