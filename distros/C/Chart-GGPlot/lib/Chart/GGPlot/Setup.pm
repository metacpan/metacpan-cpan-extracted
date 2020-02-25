package Chart::GGPlot::Setup;

# ABSTRACT: Import stuffs into Chart::GGPlot classes

use 5.016;
use warnings;

our $VERSION = '0.0009'; # VERSION

use utf8;
use feature ':5.16';

use Import::Into;

use Alt::Data::Frame::ButMore 0.0053;
use Data::Frame::Autobox ();

use Carp;
use Data::Dumper ();
use Function::Parameters 2.001003;
use Log::Any qw($log);
use Log::Any::Adapter;
use Safe::Isa 1.000010 ();
use PerlX::Maybe ();

use Syntax::Keyword::Try ();
use Module::Load;
use Moose 2.1400;
use Moose::Role               ();
use MooseX::Aliases           ();
use MooseX::MungeHas          ();
use MooseX::StrictConstructor ();
use boolean                   ();

use List::AllUtils qw(uniq);

# for debug
if (my $trace_level = $ENV{CHART_GGPLOT_TRACE} ) {
    load Log::Dispatch;
    load POSIX, qw(strftime);
    my $logger = Log::Dispatch->new(
        outputs => [
            [
                'Screen',
                min_level => 'debug',
                newline   => 1,
                stderr    => 1,
            ]
        ],
        callbacks => sub {
            my %params = @_;
            my $msg = $params{message};
            my $level = uc($params{level});
            return sprintf("%s [Chart::GGPlot $level] %s", strftime('%Y-%m-%d %H:%M:%S', localtime(time)), $msg);
        },
    );
    Log::Any::Adapter->set( { category => qr/^Chart::GGPlot/ },
        'Dispatch', dispatcher => $logger, );
}

sub import {
    my ( $class, @tags ) = @_;

    unless (@tags) {
        @tags = qw(:base);
    }
    $class->_import( scalar(caller), @tags );
}

sub _import {
    my ( $class, $target, @tags ) = @_;

    my @remove_module = @tags;
    for my $tag ( uniq @tags ) {
        $class->_import_tag( $target, $tag );
    }
}

sub _import_tag {
    my ( $class, $target, $tag ) = @_;

    if ( $tag eq ':base' ) {
        strict->import::into($target);
        warnings->import::into($target);
        utf8->import::into($target);
        feature->import::into( $target, ':5.16' );

        Carp->import::into($target);
        Data::Dumper->import::into($target);
        Function::Parameters->import::into($target);
        Log::Any->import::into( $target, '$log' );
        Safe::Isa->import::into($target);
        PerlX::Maybe->import::into($target);
        Syntax::Keyword::Try->import::into($target);
        boolean->import::into($target);

        Data::Frame::Autobox->import::into($target);
    }
    elsif ( $tag eq ':class' ) {
        $class->_import_tag( $target, ':base' );

        Function::Parameters->import::into( $target,
            qw(classmethod :modifiers) );

        Moose->import::into($target);
        MooseX::Aliases->import::into($target);
        MooseX::MungeHas->import::into($target);
        MooseX::StrictConstructor->import::into($target);
    }
    elsif ( $tag eq ':role' ) {
        $class->_import_tag( $target, ':base' );

        Function::Parameters->import::into( $target,
            qw(classmethod :modifiers) );

        Moose::Role->import::into($target);
        MooseX::Aliases->import::into($target);
        MooseX::MungeHas->import::into($target);
    }
    elsif ( $tag eq ':pdl' ) {
        require PDL::Lite;
        require PDL::Core;
        #require PDL::IO::Dumper;
        require PDL::SV;
        require PDL::Factor;
        require PDL::DateTime;
        require Role::Tiny;

        PDL::Lite->import::into($target);
        PDL::Core->import::into( $target, qw(pdl null) );
        #PDL::IO::Dumper->import::into($target);

        Role::Tiny->apply_roles_to_package( 'PDL', 'Data::Frame::PDL' );

        # "use PDL::SV;" (or PDL::Factor) would import names like float,
        # thus would pollute caller namespace and cause a warning with
        # Test::V0. So we don't do PDL::SV->import::into
    }
    else {
        croak qq["$tag" is not exported by the $class module\n];
    }
}

# this is similar to what the "aliased" module does, but "aliased"
#  does not work with Import::Into.
sub _alias {
    my ( $class, $target, $from, $to ) = @_;

    $from->import::into($target);
    no strict 'refs';
    *{"${target}::${to}"} = sub { $from };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Setup - Import stuffs into Chart::GGPlot classes

=head1 VERSION

version 0.0009

=head1 SYNOPSIS

    use Chart::GGPlot::Setup;

=head1 DESCRIPTION

This module is a building block of classes in the Chart::GGPlot project.
It uses L<Import::Into> to import stuffs into classes, thus largely removing
the annoyance of writing a lot "use" statements in each class.

=head1 SEE ALSO

L<Import::Into>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
