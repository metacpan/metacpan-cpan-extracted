package AppConfig::Exporter;

use warnings;
use strict;
use Exporter;
use AppConfig qw(:argcount);

=head1 NAME

AppConfig::Exporter - Allow modules to import AppConfig sections from a shared configuration.

=cut 

our $VERSION = q(1.5);

=head1 SYNOPSIS

    package MyConfig;
    use base qw( AppConfig::Exporter );

    __PACKAGE__->configure( Config_File => 'myfile.conf', 
                            AppConfig_Options => { CASE => 0 }, 
                            AppConfig_Define => { Fun_Pickles => {ARGCOUNT => ARGCOUNT_LIST} } );
    1;

=head1 USAGE

B<AppConfig::Exporter> is intended to be subclassed to specify your configuration file and any options.  Then, you can request a hash of any section from the configuration file by specifying it as a symbol to be imported in the B<use> statement:

    # myfile.conf
    [fruit]
 
    oranges = 'tasty'
    apples  = 'sweet'

    # some code elsewhere... 

    use MyConfig qw(fruit);
    print "$fruit{oranges}!";  # tasty!

    my $appconfig = MyConfig->AppConfig;

=cut

our @ISA = qw(Exporter);
our @EXPORT_OK;

my $appconfig;

=head1 CONFIGURATION

=over

=item configure

This is how your class is initialized.  You must specify a Config_File, and you may specify a hashref of AppConfig_Options and AppConfig_Define.

=over 

=item Config_File

Required - path to your AppConfig compatible config file

    __PACKAGE__->configure( Config_File => 'myfile.conf' );


=item AppConfig_Options

Hash ref that will be fed to AppConfig - you can override this module's defaults, which are:

        CASE   => 1,
        CREATE => 1,
        GLOBAL => {
            ARGCOUNT => ARGCOUNT_ONE,
        }

For example:

    __PACKAGE__->configure( Config_File => 'myfile.conf', 
                            AppConfig_Options => { CASE => 0 } ); 

=item AppConfig_Define

Hash ref that will be fed to AppConfig as a define statement if you wish for a specific variable to have different properties than the global ones.  

B<Note:> So that you can use AppConfig's constants, this module automatically imports AppConfig's b<:argcount> tag into your package for you.


    __PACKAGE__->configure( Config_File => 'myfile.conf', 
                            AppConfig_Define => { Fun_Pickles => {ARGCOUNT => ARGCOUNT_LIST} } );

=back

=cut 

sub configure {
    my $class = shift;
    my %opts = @_;
    
    die "$class is already configured" if $appconfig;

    my $config_file = delete $opts{Config_File} or die __PACKAGE__ . ' requires a Config_File argment';

    $appconfig = AppConfig->new(
				{
				    CASE   => 1,
				    CREATE => 1,
				    GLOBAL => { 
					ARGCOUNT => ARGCOUNT_ONE,
				    },
				    defined $opts{AppConfig_Options} ? %{$opts{AppConfig_Options}} : (),
				},
				defined $opts{AppConfig_Define} ? %{$opts{AppConfig_Define}}: (),  
				);
    
    $appconfig->file( $config_file ) or die qq(Error reading config file "$config_file");
}

=item import

This does the heavy lifting using the Exporter.  You don\'t call this directly - B<use> will do it for you.

=cut

sub import {
    my $class = shift;
    my @tags  = @_;
    {
	no strict qw( refs ) ;
	for my $section ( @tags ) {
	    push @EXPORT_OK, "\%$section";
	    *{"$section"} = { $appconfig->varlist("^${section}_", 1) };
	    __PACKAGE__->export_to_level( 1, $class, "\%$section" );
	}
    }
    my $callpkg = caller(0);
    eval "package $callpkg; use AppConfig qw(:argcount);";
    die $@ if $@;
}

=item AppConfig

You can use this to access the the raw B<AppConfig> object that the exporter sources for configuration. 

=back

=cut

sub AppConfig{
    return $appconfig;
}

=head1 AUTHOR

Ben H Kram, C<< <bkram at dce.harvard.edu> >>

=head1 ACKNOWLEDGEMENTS

Andy Wardley, for his excellent AppConfig module.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Harvard University and Fellows, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of AppConfig::Exporter
