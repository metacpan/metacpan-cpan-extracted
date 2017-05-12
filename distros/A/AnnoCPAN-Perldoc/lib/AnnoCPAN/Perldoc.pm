require 5;
use 5.006;
package AnnoCPAN::Perldoc;
use strict;
use warnings;
use base 'Pod::Perldoc';

our $VERSION = '0.10';

sub maybe_generate_dynamic_pod {
    my($self, $found_things) = @_;

    if ($self->opt_f or $self->opt_q) {
        warn "Warning: -f and -q do not support annotations yet\n";
        return shift->SUPER::maybe_generate_dynamic_pod(@_);
    }

    my @dynamic_pod;
    
    $self->filter_pod($found_things, \@dynamic_pod);

    my ($buffd, $buffer) = $self->new_tempfile('pod', 'dyn');
    
    push @{ $self->{'temp_file_list'} }, $buffer;
     # I.e., it MIGHT be deleted at the end.
    
    print $buffd @dynamic_pod  or die "Can't print $buffer: $!";
    close $buffd        or die "Can't close $buffer: $!";
    
    @$found_things = $buffer;
      # Yes, so found_things never has more than one thing in
      #  it, by time we leave here
    
    $self->add_formatter_option('__filter_nroff' => 1);

    return;
}


sub filter_pod {
    my($self, $found_things, $pod) = @_;

    Pod::Perldoc::DEBUG > 2 and print "Search: @$found_things\n";

    my $file = shift @$found_things;
    open(F, "<", $file)               # "Funk is its own reward"
        or die("Can't open $file $!");

    Pod::Perldoc::DEBUG > 2 and
     print "Going to filter for $file\n";
    
    my $content = do { local $/; <F> };

    my ($filter_class) = 'AnnoCPAN::Perldoc::Filter';

    eval "require $filter_class";
    if($@) {
        die "Couldn't load filter class '$filter_class': $@\n";
    }

    my $filter = $filter_class->can('new')
        ? $filter_class->new
        : $filter_class
    ;

    @$pod = $filter->filter($content);

    close F  or die "Can't close $file $!";
    return;
}

1;

__END__

=head1 NAME

AnnoCPAN::Perldoc - Integrate AnnoCPAN notes locally into perldoc

=head1 SYNOPSYS

    # This is a fully functional 'perldoc'
    use AnnoCPAN::Perldoc;
    AnnoCPAN::Perldoc->run;

=head1 DESCRIPTION

AnnoCPAN is a web interface for the documentation of all the modules on CPAN,
where users can add annotations on the margin of specific paragraphs throughout
the POD. The master AnnoCPAN site is located at http://annocpan.org/.

AnnoCPAN-Perldoc provides a substitute for the 'perldoc' command that displays
the annotations locally and without requiring a connection to the Internet. 
It works by using a local note database that can be downloaded from

    http://annocpan.org/annopod.db

This is an SQLite3 database; the file should be saved in one of these
locations:

    $HOME
    $USERPROFILE
    $ALLUSERSPROFILE
    /var/annocpan

It can also be called .annopod.db, to hide it in Unix-like systems. It is your
resposibility to keep this file as up-to-date as you want. Future versions may
include an automatic update feature (which will require network connectivity).

=head1 SEE ALSO

L<annopod>,
L<AnnoCPAN>,
L<Pod::Perldoc>

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2005 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

