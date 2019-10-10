package Catmandu::SFX;

use strict;
our $VERSION = '0.02';

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Moo;
use POSIX qw(strftime);

sub parse_sfx_threshold {
    my ($self,$str) = @_;
   
    my $res = { raw => $str , start => {} , end => {} , limit => {} , years => [] };

    # Parse the Available from part...
    if ($str =~ m{^Available\s+(.*)\.}) {
        my $from = $1;

        if (defined $from && $from =~ m{
                (in|from)
                \s+
                (\d+)
                (\s+volume:\s+(\S+))?
                (\s+issue:\s+(\S+))?
                (.*)
            }x) {
            $res->{start}->{year}   = $2;
            $res->{start}->{volume} = $4 if $3;
            $res->{start}->{issue}  = $6 if $5;
        }

        my $until = $7;

        if (defined $until && $until =~ m{
                until
                \s+
                (\d+)
                (\s+volume:\s+(\S+))?
                (\s+issue:\s+(\S+))?
            }x) {
            $res->{end}->{year}     = $1 if $1;
            $res->{end}->{volume}   = $3 if $3;
            $res->{end}->{issue}    = $5 if $5;
        }
    }
   
    # Parse the Most recent part...
    if ($str =~ m{
            Most
            \s+
            recent
            \s+
            (\d+)
            \s+
            (year|month)
            \(s\)
            \s+
            (not\s+)?
            available
            \.
    
        }x) {
        $res->{limit}->{num}  = $1;
        $res->{limit}->{type} = $2;
        $res->{limit}->{available} = $3 ? 0 : 1; 
    }

    if (exists $res->{end}->{year} || exists $res->{limit}->{num}) {
        $res->{is_running} = 0;
    }
    else {
        $res->{is_running} = 1;
    }

    $res->{years} = $self->parse_year_ranges($res);

    $res->{human} = $self->parse_human_ranges($res);

    $res;
}

sub parse_human_ranges {
    my ($self,$parsed) = @_;
    my $years = $parsed->{years};

    my @human = ();

    if (is_array_ref($years) && @$years > 0) {
        push @human , $years->[0];
        push @human , $years->[-1] if @$years > 1;
    }

    if ($parsed->{is_running} == 0) {
        return join(' - ', @human);
    }   
    else {
        return shift(@human) . " - ";   
    }
}

sub parse_year_ranges {
    my ($self,$parsed) = @_;

    # Calculate which years are available for users...
    my $this_year = strftime("%Y", localtime);

    my ($start_year,$end_year);
    
    $start_year = $parsed->{start}->{year} if exists $parsed->{start}->{year};
    $start_year //= $this_year;

    $end_year   = $parsed->{end}->{year}   if exists $parsed->{end}->{year};
    $end_year //= $this_year;

    # If most recent X years(s) are not available
    if (exists $parsed->{limit} && 
        $parsed->{limit}->{num} && 
        $parsed->{limit}->{type} eq 'year' &&
        $parsed->{limit}->{available} == 0) {
        $end_year -= $parsed->{limit}->{num} + 1;
    }

    if ($start_year < $end_year) {
        return [ ($start_year .. $end_year) ];
    } 
    else {
        return [ ($end_year .. $start_year) ];
    }
}

sub parse_sfx_year_range {
    my ($self, $years) = @_;

    return "" unless is_array_ref($years) && @$years > 0;

    my $curryear = [localtime time]->[5] + 1900;
    my %h;

    foreach (@$years) {
       $h{$_} = 1;
    }

    my $start = undef;
    my $prev  = undef;
    my $human = '';

    foreach (sort { $a <=> $b } keys %h) {
        if (! defined $start) {
           $start = $_;
        }
        elsif ($_ == $prev + 1) { }
        elsif ($start == $prev) {
           $human .= "$start ; ";
           $start = $_;
        }
        else {
           $human .= "$start - $prev ; ";
           $start = $_;
        }
        $prev = $_;
    }

    $human .= "$start - $prev";

    return $human;
}

1;

__END__

=encoding utf-8

=head1 NAME

Catmandu::SFX - Catmandu modules for parsing SFX data

=head1 DESCRIPTION

Catmandu::SFX provides methods to work with SFX input within the L<Catmandu>
framework. See L<Catmandu::Introduction> and L<http://librecat.org/> for an
introduction into Catmandu.

=head1 CATMANDU MODULES

=over

=item * L<Catmandu::Fix::sfx_threshold>

=item * L<Catmandu::Fix::sfx_year_range>

=back

=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
