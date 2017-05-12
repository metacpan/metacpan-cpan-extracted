#!/usr/bin/perl

use strict;
use warnings;
use App::Starter;
use Getopt::Long;

my %opt;
GetOptions( \%opt, 'name=s' , 'template=s' );
App::Starter->new( { template => $opt{template} ,  name => $opt{name} , replace => { app => $opt{name} , app_prefix => lc $opt{name}  }  } )->create;

1;
__END__

=head1 NAME

app-starter-catalyst.pl - App::Starter script file for catalyst.

=head1 SYNOPSIS

 app-starter-catalyst.pl --template  --name MyApp

=head1 DESCRIPTION

automatically set rule for app app_prefix from --name options.

=head1 SEE ALSO

L<App::Starter>

=head1 AUTHOR

Tomohiro Teranishi

=cut

