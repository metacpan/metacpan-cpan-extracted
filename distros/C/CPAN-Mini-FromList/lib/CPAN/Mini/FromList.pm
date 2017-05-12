package CPAN::Mini::FromList;

use warnings;
use strict;

our $VERSION = '0.05';
# ABSTRACT: create a minimal CPAN mirror from a list of modules you specify

use CPAN::Mini;
use Data::Dumper;
use File::Spec::Functions;
use base qw(CPAN::Mini);




our %dists = ();

sub update_mirror {
    my $self = shift;
    my @args = @_;
    my %args=@args;
    
    foreach my $d (@{$args{list}}) {
        $dists{$d} = 1;        
    }

    CPAN::Mini->update_mirror(@args, 'module_filters', [\&_fromlist_filter]);
}

sub _fromlist_filter {
   my $module = shift;
   return 1 if ! $dists{$module};
   return 0;
}


sub delete_02packages {
    my ($class,$local)=@_;
    my $packages02=catfile($local,qw(modules 02packages.details.txt.gz));
    if (-e $packages02) {
        unlink ($packages02) || die "Cannot unlink $packages02: $!";
    }
}


sub generate_fake_02packages {
    my ($class,$local)=@_;
    eval {
        my $packages=catfile($local,qw(modules 02packages.details.txt));
        my @files=File::Find::Rule->file()->name('*.gz')->relative->in(
            catdir($local,qw(authors id)));    
        open(my $fh,'>',$packages) || die "Cannot write to $packages: $!";
        my $linecnt=@files;
        my $now=scalar localtime;
        print $fh <<"EOHEAD";
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  Fake 02packges generate by CPAN::Mini::FromList
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   CPAN::Mini::FromList 
Line-Count:   $linecnt
Last-Updated: $now

EOHEAD
        foreach (@files) {
            print $fh "Fake                   undef    $_\n";
        }
        close $fh;
        $class->delete_02packages($local);
        system('gzip',$packages);
    };
    print $@ if $@;
}


q{  listening to:
    CPAN discussions at the Oslo QA Hackathon    
};



=pod

=head1 NAME

CPAN::Mini::FromList - create a minimal CPAN mirror from a list of modules you specify

=head1 VERSION

version 0.05

=head1 SYNOPSIS

Unless you need to do something unusual, you probably should be looking 
at C<minicpan-fromlist>.

    use CPAN::Mini::FromList;

    CPAN::Mini::FromList->update_mirror(%args);
    ...

=head1 NAME

CPAN::Mini::FromList - create a minimal CPAN mirror of modules you specify

=head1 METHODS

=head2 update_mirror %args

Begins the process of creating a local CPAN mirror, but only downloads   
modules specified by the user. See the documentation in CPAN::Mini for 
more details on the arguments.

=head3 delete_02packages

Delete 02packages.details.txt.gz

=head3 generate_fake_02packages

Generate a fake 02packages.details.txt.gz containing only the packages
listed.

=head1 AUTHOR

Thomas Klausner, C<< domm@cpan.org >>

based on CPAN::Mini::Phalanx100 by Steve Peters

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cpan-mini-fromlist@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<CPAN::Mini>

=head1 ACKNOWLEDGEMENTS

Thanks to...

Ricardo Signes - for writing  L<CPAN::Mini>, which does 99% of the work in this module

Steve Peters - for writing CPAN::Mini::Phalanx100, from which I copied most of this code

=head1 COPYRIGHT & LICENSE

Copyright 2008 Thomas Klausner, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__ 




