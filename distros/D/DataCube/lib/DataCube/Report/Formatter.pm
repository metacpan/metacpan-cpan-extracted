

package DataCube::Report::Formatter;


use strict;
use warnings;


sub new {
    my($class,%opts) = @_;
    bless {}, ref($class) || $class;
}

sub dir {
    my($self,$path) = @_;
    opendir(my $D, $path) or die "DataCube::FileSplitter(dir):\ncant open directory:$path\n$!\n";
    grep {/[^\.]/} readdir($D);
}

sub sort_format {
    my($self,$path) = @_;
    my @lines = $self->fcon($path);
    @lines[1..$#lines] = sort @lines[1..$#lines];
    {
        local $| = 1;
        open(my $F, '>', $path)
            or die "DataCube::Report::Formatter(sort_format):\ncant open file for writing:\n$path\n$!\n";
        print $F join("\n",@lines);
        close $F;
    }
    return $self;
}

sub fcon {
    my($self,$path) = @_;
    open(my $F, '<' , $path)
        or die "DataCube::Report::Formatter(fcon):\ncant open:\n$path\n$!\n";
    my @lines = grep {/\S/} <$F>;
    $_ =~ s/\n//g for @lines;
    return @lines;
}






1;



__DATA__

__END__

=head1 AUTHOR

David Williams, E<lt>david@namimedia.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by David Williams

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

