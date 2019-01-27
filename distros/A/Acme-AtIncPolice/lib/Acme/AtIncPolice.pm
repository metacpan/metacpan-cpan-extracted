package Acme::AtIncPolice;
use 5.008001;
use strict;
use warnings;
use Carp;

our $VERSION = "0.02";

BEGIN {
    use Tie::Trace qw/watch/;
    no warnings 'redefine';

    *Tie::Trace::_output_message = sub {
        my ($self, $class, $value, $args) = @_;
        if (!$value) {
            return;
        }

        my ($msg, @msg) = ('');

        my $caller    =  $self->{options}->{caller};
        my $_caller_n = 1;
        while (my $c = (caller $_caller_n)[0]) {
            if (not $c) {
                last;
            } elsif ($c  !~ /^Tie::Trace/) {
                last;
            }
            $_caller_n++;
        }

        my @caller = map $_ + $_caller_n, ref $caller ? @{$caller} : $caller;
        my(@filename, @line);
        foreach(@caller){
            my($f, $l) = (caller($_))[1, 2];
            next unless $f and $l;

            push @filename, $f;
            push @line, $l;

        }

        my $location = @line == 1 ? " at $filename[0] line $line[0]." :
                                    join "\n", map " at $filename[$_] line $line[$_].", (0 .. $#filename);
        my($_p, $p) = ($self, $self->parent);
        while($p){
            my $s_type = ref $p->{storage};
            my $s = $p->{storage};
            if($s_type eq 'HASH'){
                push @msg, "{$_p->{__key}}";
            }elsif($s_type eq 'ARRAY'){
                push @msg, "[$_p->{__point}]";
            }
            $_p = $p;
            last if ! ref $p or ! ($p = $p->parent);
        }
        $msg = @msg > 0 ? ' => ' . join "", reverse @msg : "";


        $value = '' unless defined $value;
        if ($class eq 'Scalar') {
            return("${msg} => $value$location");
        } elsif ($class eq 'Array') {
            unless(defined $args->{point}){
                $msg =~ s/^( => )(.+)$/$1\@\{$2\}/;
                return("$msg => $value$location");
            }else{
                return("${msg}[$args->{point}] => $value$location");
            }
        } elsif ($class eq 'Hash') {
            return("${msg}" . (! $self->{options}->{pkg} || @msg ? "" : " => "). "{$args->{key}} => $value$location");
        }
    };


    *Tie::Trace::_carpit = sub {
        my ($self, %args) = @_;
        return if $Tie::Trace::QUIET;
        
        my $class = (split /::/, ref $self)[2];
        my $op = $self->{options} || {};
        
        # key/value checking
        if ($op->{key} or $op->{value}) {
            my $key   = $self->_matching($self->{options}->{key},   $args{key});
            my $value = $self->_matching($self->{options}->{value}, $args{value});
            if (($args{key} and $op->{key}) and $op->{value}) {
                return unless $key or $value;
            } elsif($args{key} and $op->{key}) {
                return unless $key;
            } elsif($op->{value}) {
                return unless $value;
            }
        }
        
        # debug type
        my $value = $self->_debug_message($args{value}, $op->{debug}, $args{filter});
        # debug_value checking
        return unless $self->_matching($self->{options}->{debug_value}, $value);
        # use scalar/array/hash ?
        return unless grep lc($class) eq lc($_) , @{$op->{use}};
        # create warning message
        my $watch_msg = '';
        my $msg = $self->_output_message($class, $value, \%args);
        if(defined $self->{options}->{pkg}){
            $watch_msg = sprintf("%s:: %s", @{$self->{options}}{qw/pkg var/});
        } else {
            $msg =~ s/^ => // if $msg;
        }
        if ($msg) {
            croak $watch_msg . $msg . "\n";
        }
    };

    watch @INC, (
        debug => sub {
            my ($self, $things) = @_;
            for my $thing (@$things) {
                my $ref = ref($thing);
                if ($ref) {
                    return "Acme::AtIncPolice does not allow contamination of \@INC";
                }
            }
        },
        r => 0,
    );
};


1;
__END__

=encoding utf-8

=head1 NAME

Acme::AtIncPolice - The police that opponents to @INC contamination

=head1 SYNOPSIS

    use Acme::AtIncPolice;
    # be killed by Acme::AtIncPolice
    push @INC, sub {
        my ($coderef, $filename) = @_;
        my $modfile = "lib/$filename";
        if (-f $modfile) {
            open my $fh, '<', $modfile;
            return $fh;
        }
    };
    # be no-op ed by Acme::AtIncPolice
    push @INC, "lib";

=head1 DESCRIPTION

If you use Acme::AtIncPolice, your program be died when detects any reference value from @INC.

=head2 MOTIVE

@INC hooks is one of useful feature in the Perl. It's used inside of some clever modules.

But, @INC hooks provoke confuse in several cases. 

A feature that resolve library path dynamically is needed on your project that is simple web application? Really? 

The answer is "NO".

Let's go on. Acme::AtIncPolice gives clean programming experience to you. Under Acme::AtIncPolice, @INC hooks is prohibited.

If you found a "smelly" program, Let use Acme::AtIncPolice on it.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

