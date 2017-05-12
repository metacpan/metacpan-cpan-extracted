package CPAN::Testers::WWW::Reports::Parser::YAML;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.06';

#----------------------------------------------------------------------------
# Library Modules

use YAML::XS    qw(Load LoadFile);

#----------------------------------------------------------------------------
# Variables

#----------------------------------------------------------------------------
# The Application Programming Interface

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
}

# full data set methods

sub register {
    my $self = shift;
    my %hash = @_;
    $self->{file} = $hash{file};
    $self->{data} = $hash{data};
}

sub raw_data {
    my $self = shift;
    if($self->{file}) {
        seek($self->{file},0,0) if(ref $self->{file} eq 'GLOB');
        return LoadFile($self->{file});
    }
    return Load($self->{data});
}

q{ Kein Zurück für dich };

__END__

=head1 NAME

CPAN::Testers::WWW::Reports::Parser::YAML - CPAN Testers YAML parser

=head1 SYNOPSIS

  use CPAN::Testers::WWW::Reports::Parser::YAML;

  my $obj = CPAN::Testers::WWW::Reports::Parser::YAML->new();

  $obj->register( file => $file );  # local file name
  $obj->register( data => $data );  # reference to a data block

  my $data = $obj->raw_data();

=head1 DESCRIPTION

This distribution is used to extract the data from a YAML file containing
metadata regarding reports submitted by CPAN Testers, and available from the 
CPAN Testers website.

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Instatiates the object.

=back

=head2 Public Methods

=over

=item * register

=item * raw_data

=back

=head1 CPAN TESTERS FUND

CPAN Testers wouldn't exist without the help and support of the Perl 
community. However, since 2008 CPAN Testers has grown far beyond the 
expectations of it's original creators. As a consequence it now requires
considerable funding to help support the infrastructure.

In early 2012 the Enlightened Perl Organisation very kindly set-up a
CPAN Testers Fund within their donatation structure, to help the project
cover the costs of servers and services.

If you would like to donate to the CPAN Testers Fund, please follow the link
below to the Enlightened Perl Organisation's donation site.

F<https://members.enlightenedperl.org/drupal/donate-cpan-testers>

If your company would like to support us, you can donate financially via the
fund link above, or if you have servers or services that we might use, please
send an email to admin@cpantesters.org with details.

Our full list of current sponsors can be found at our I <3 CPAN Testers site.

F<http://iheart.cpantesters.org>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT: http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-WWW-Reports-Parser

=head1 SEE ALSO

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>,
F<http://blog.cpantesters.org/>

=head1 AUTHOR

  Barbie <barbie@cpan.org> 2009-present

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2014 Barbie <barbie@cpan.org>

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
