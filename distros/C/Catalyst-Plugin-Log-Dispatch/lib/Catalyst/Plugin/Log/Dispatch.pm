package Catalyst::Plugin::Log::Dispatch;

use warnings;
use strict;

our $VERSION = '0.121';

#use base 'Catalyst::Base';
use vars qw/$HasTimePiece $HasTimeHiRes/;
use UNIVERSAL::require;

BEGIN {
    Log::Dispatch::Config->use or warn "$@\nIt moves without using Log::Dispatch::Config.\n";
    $HasTimeHiRes = 1 if( Time::HiRes->use(qw/tv_interval/) );
    $HasTimePiece = 1 if( Time::Piece->use );
};
$Catalyst::Plugin::Log::Dispatch::CallerDepth = 0;

use IO::Handle;


# Module implementation here

sub setup {
    if( $Catalyst::VERSION >= 5.8 ) {
        MRO::Compat->use or die "can not use MRO::Compat : $@\n";
    }
    else {
        NEXT->use or die "can not use NEXT : $@\n";
    }
    my $c = shift;
    my $old_log = undef;
    if ( $c->log and ref( $c->log ) eq 'Catalyst::Log' ) {
        $old_log = $c->log;
    }
    $c->log( Catalyst::Plugin::Log::Dispatch::Backend->new );
    
    #Make it an array with one element if its a hashref
    if (ref ( $c->config->{'Log::Dispatch'} ) eq 'HASH') {
        $c->config->{'Log::Dispatch'} = [ $c->config->{'Log::Dispatch'} ];
    }
    
    unless ( ref( $c->config->{'Log::Dispatch'} ) eq 'ARRAY' ) {
        push(
            @{ $c->config->{'Log::Dispatch'} },
            {   class     => 'STDOUT',
                name      => 'default',
                min_level => 'debug',
                format    => '[%p] %m%n'
            }
        );

    }
    foreach my $tlogc ( @{ $c->config->{'Log::Dispatch'} } ) {
        my %logc = %{$tlogc};
        if ( $logc{'class'} eq 'STDOUT' or $logc{'class'} eq 'STDERR' ) {
            my $io = IO::Handle->new;
            $io->fdopen( fileno( $logc{'class'} ), 'w' );
            $logc{'class'}  = 'Handle';
            $logc{'handle'} = $io;
        }
        my $class = sprintf( "Log::Dispatch::%s", $logc{'class'} );
        delete $logc{'class'};
        $logc{'callbacks'} = [$logc{'callbacks'}] if(ref($logc{'callbacks'}) eq 'CODE');
        
        if(exists $logc{'format'} and defined $Log::Dispatch::Config::CallerDepth ) {
            my $callbacks = Log::Dispatch::Config->format_to_cb($logc{'format'},0);
            if(defined $callbacks) {
                $logc{'callbacks'} = [] unless($logc{'callbacks'});
                push(@{$logc{'callbacks'}}, $callbacks);
            }
        }
        if( exists $logc{'format_o'} and length( $logc{'format_o'} ) ) {
            my $callbacks = Catalyst::Plugin::Log::Dispatch->_format_to_cb_o($logc{'format_o'},0);
            if(defined $callbacks) {
                $logc{'callbacks'} = [] unless($logc{'callbacks'});
                push(@{$logc{'callbacks'}}, $callbacks);
            }
        }
        elsif(!$logc{'callbacks'}) {
            $logc{'callbacks'} = sub { my %p = @_; return "$p{message}\n"; };
        }
        $class->use or die "$@";
        my $logb = $class->new(%logc);
        $logb->{rtf} = $logc{real_time_flush} || 0;
        $c->log->add( $logb );
    }
    
    if ($old_log && defined __log_dispatch_get_body( $old_log ) ) {
        my @old_logs;
        foreach my $line ( split /\n/, __log_dispatch_get_body( $old_log ) ) {
            if ( $line =~ /^\[(\w+)] (.+)$/ ) {
                push( @old_logs, { level => $1, msg => [$2] } );
            }
            elsif( $line =~ /^\[(\w{3} \w{3}[ ]{1,2}\d{1,2}[ ]{1,2}\d{1,2}:\d{2}:\d{2} \d{4})\] \[catalyst\] \[(\w+)\] (.+)$/ ) {
                push( @old_logs, { level => $2, msg => [$3] } );
            }
            else {
                push( @{ $old_logs[-1]->{'msg'} }, $line );
            }
        }
        foreach my $line (@old_logs) {
            my $level = $line->{'level'};
            $c->log->$level( join( "\n", @{ $line->{'msg'} } ) );
        }
    }
    if( $Catalyst::VERSION >= 5.8 ) {
        return $c->maybe::next::method( @_ );
    }
    else {
        $c->NEXT::setup(@_);
    }
}


sub __log_dispatch_get_body {
    my $log = shift;
    return $Catalyst::VERSION >= 5.8 ? $log->_body : $log->body;
}
use Data::Dumper;
# copy and paste from Log::Dispatch::Config
# please teach a cool method.
sub _format_to_cb_o {
    my($class, $format, $stack) = @_;
    return undef unless defined $format;
    
    # caller() called only when necessary
    my $needs_caller = $format =~ /%[FLP]/;
    if( $HasTimeHiRes ) {
        return sub {
            my %p = @_;
            $p{p} = delete $p{level};
            $p{m} = delete $p{message};
            $p{n} = "\n";
            $p{'%'} = '%';
            $p{i} = $$;
            if ($needs_caller) {
                my $depth = 0; 
                $depth++ while caller($depth) =~ /^Catalyst::Plugin::Log::Dispatch/;
                $depth += $Catalyst::Plugin::Log::Dispatch::CallerDepth;
                @p{qw(P F L)} = caller($depth);
            }
            
            my ($t,$ms) = Time::HiRes::gettimeofday();
            $ms = sprintf('%06d', $ms);
            my $log = $format;
            $log =~ s{
                         (%d(?:{(.*?)})?)|   # $1: datetime $2: datetime fmt
                         (%MS)|              # $3: milli second
                         (?:%([%pmFLPni]))   # $4: others
                 }{
                     if ($1 && $2) {
                         _strftime_o($2,$t);
                     }
                     elsif ($1) {
                         scalar localtime;
                     }
                     elsif ($3) {
                         $ms;
                     }
                     elsif ($4) {
                         $p{$4};
                     }
                 }egx;
            return $log;
        };
    }
    else {
        return sub {
            my %p = @_;
            $p{p} = delete $p{level};
            $p{m} = delete $p{message};
            $p{n} = "\n";
            $p{'%'} = '%';
            $p{i} = $$;
            if ($needs_caller) {
                my $depth = 0; 
                $depth++ while caller($depth) =~ /^Catalyst::Plugin::Log::Dispatch/;
                $depth += $Catalyst::Plugin::Log::Dispatch::CallerDepth;
                @p{qw(P F L)} = caller($depth);
            }
            
            my $log = $format;
            $log =~ s{
                         (%d(?:{(.*?)})?)|   # $1: datetime $2: datetime fmt
                         (?:%([%pmFLPn]))    # $3: others
                 }{
                     if ($1 && $2) {
                         _strftime_o($2);
                     }
                     elsif ($1) {
                         scalar localtime;
                     }
                     elsif ($3) {
                         $p{$3};
                     }
                 }egx;
            return $log;
        };
    }
}

sub _strftime_o {
    my $fmt = shift;
    my $time = shift || time;
    if ($HasTimePiece) {
        return Time::Piece->new($time)->strftime($fmt);
    } else {
        require POSIX;
        return POSIX::strftime($fmt, localtime($time));
    }
}


1;

package Catalyst::Plugin::Log::Dispatch::Backend;

use strict;

use base qw/Log::Dispatch Class::Accessor::Fast/;

use Time::HiRes qw/gettimeofday/;
use Data::Dump;
use Data::Dumper;

{
    foreach my $l (qw/debug info warn error fatal/) {
        my $name = $l;
        $name = 'warning'  if ( $name eq 'warn' );
        $name = 'critical' if ( $name eq 'fatal' );

        no strict 'refs';
        *{"is_${l}"} = sub {
            my $self = shift;
            return $self->level_is_valid($name);
        };

        *{"$l"} = sub {
            my $self = shift;
            my %p = (level => $name,
                     message => "@_");
            local $Log::Dispatch::Config::CallerDepth += 1;
            local $Catalyst::Plugin::Log::Dispatch::CallerDepth += 3;
            if( keys( %{ $self->{outputs} } ) ) {
                foreach (keys %{ $self->{outputs} }) {
                    my %h = %p;
                    $h{name} = $_;
                    if( $self->{outputs}->{$_}->{rtf} ) {
                        $self->{outputs}->{$_}->log(%h);
                    }
                    else {
                        $h{message} = $self->{outputs}->{$_}->_apply_callbacks(%h)
                            if($self->{outputs}->{$_}->{callbacks});
                        push(@{$self->_body}, \%h);
                    }
                }
            }
            else {
                push(@{$self->_body}, \%p);
            }
        };
    }
}

sub new {
    my $pkg  = shift;
    my $this = $pkg->SUPER::new(@_);
    $this->mk_accessors(qw/abort _body/);
    $this->_body([]);
    return $this;
}


sub dumper {
    my $self = shift;
    return $self->debug( Data::Dumper::Dumper(@_) );
}

sub _dump {
    my $self = shift;
    return $self->debug( Data::Dump::dump(@_) );
}

sub level_is_valid {
    my $self = shift;
    return 0 if ( $self->abort );
    return $self->SUPER::level_is_valid(@_);
}

sub _flush {
    my $self = shift;
    if ( $self->abort || !(scalar @{$self->_body})) {
        $self->abort(undef);
    }
    else {
        foreach my $p (@{$self->_body}) {
            local $self->{outputs}->{$p->{name}}->{callbacks} = undef;
            $self->{outputs}->{$p->{name}}->log(%{$p});
        }
    }
    $self->_body([]);
}


1;    # Magic true value required at end of module
__END__


=head1 NAME

Catalyst::Plugin::Log::Dispatch - Log module of Catalyst that uses Log::Dispatch


=head1 VERSION

This document describes Catalyst::Plugin::Log::Dispatch version 2.15


=head1 SYNOPSIS

    package MyApp;

    use Catalyst qw/Log::Dispatch/;

configuration in source code

    MyApp->config->{ Log::Dispatch } = [
        {
         class     => 'File',
         name      => 'file',
         min_level => 'debug',
         filename  => MyApp->path_to('debug.log'),
         format    => '[%p] %m %n',
        }];

in myapp.yml

    Log::Dispatch:
     - class: File
       name: file
       min_level: debug
       filename: __path_to(debug.log)__
       mode: append
       format: '[%p] %m %n'

If you use L<Catalyst::Plugin::ConfigLoader>,
please load this module after L<Catalyst::Plugin::ConfigLoader>.

=head1 DESCRIPTION

Catalyst::Plugin::Log::Dispatch is a plugin to use Log::Dispatch from Catalyst.

=head1 CONFIGURATION

It is same as the configuration of Log::Dispatch excluding "class" and "format".

=over

=item class

The class name to Log::Dispatch::* object.
Please specify the name just after "Log::Dispatch::" of the class name.

=item format

It is the same as the format option of Log::Dispatch::Config.

=back

=head1 DEPENDENCIES

L<Catalyst>, L<Log::Dispatch>, L<Log::Dispatch::Config>

=head1 AUTHOR

Shota Takayama  C<< <shot[at]bindstorm.jp> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Shota Takayama C<< <shot[at]bindstorm.jp> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

