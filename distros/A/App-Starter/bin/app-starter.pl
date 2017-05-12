#!/usr/bin/perl

use strict;
use warnings;
use FindBin::libs;
use App::Starter;
use Getopt::Long;
use Pod::Usage;


GetOptions( \my %opt, 'config=s' , 'name=s' , 'template=s' );

App::Starter->new( { config => $opt{config} , name => $opt{name} , template => $opt{template}  } )->create;

1;
__END__

=head1 NAME

app-script.pl - App::Starter script file.

=head1 SYNOPSIS

 app-script.pl --config conf/your-config.yml --name my_application

 #or you can use ~/.app-starter/skell/your_skel  ~/.app-starter/conf/your_skel.yml with --template setting
 
 app-script.pl --template your_skel  --name my_application

=head1 SEE ALSO

L<App::Starter>

=head1 AUTHOR

Tomohiro Teranishi

=cut

