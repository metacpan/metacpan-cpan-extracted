#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  Copyright (C) 2011 - Anthony J. Lucas - kaoyoriketsu@ansoni.com



package Criteria::DateTime;
use parent qw( Criteria::Compile );


use strict;
use warnings;



our $VERSION = '0.04__7';



use DateTime ( );
use DateTime::Duration ( );
use Criteria::Compile ( );



#INIT CONFIG / VARS


use constant DATETIME_CLASS => 'DateTime';
use constant DURATION_CLASS => 'DateTime::Duration';


my $DATETIME_GRAMMAR = {
    Criteria::Compile::TYPE_DYNAMIC() => {
        qw/^(.*)_before$/ => qw/_gen_before_sub/,
        qw/^(.*)_after$/ => qw/_gen_after_sub/,
        qw/^(.*)_sooner_than$/ => qw/_gen_sooner_than_sub/,
        qw/^(.*)_later_than$/ => qw/_gen_later_than_sub/,
        qw/^(.*)_newer_than$/ => qw/_gen_newer_than_sub/,
        qw/^(.*)_older_than$/ => qw/_gen_older_than_sub/
    }
};
my $DURATION_GRAMMAR = {
    Criteria::Compile::TYPE_DYNAMIC() => {
        qw/^(.*)_longer_than$/ => qw/_gen_longer_than_sub/,
        qw/^(.*)_shorter_than$/ => qw/_gen_shorter_than_sub/
    }
};


#INITIALISATION ROUTINES


sub _init {

    my ($self, $crit, $nocomp) = @_;
    $self->SUPER::_init($crit, 1);

    #define datetime grammara
    $self->define_datetime_grammar();
    $self->define_duration_grammar();

    #validate any criteria supplied
    if ($crit and !$nocomp) {
        die('Error: Failed to compile criteria.')
            unless ($self->compile());
    }
    return 1;
}


sub define_datetime_grammar {
    Criteria::Compile::_define_grammar_dtbl($_[0], $DATETIME_GRAMMAR);
}


sub define_duration_grammar {
    Criteria::Compile::_define_grammar_dtbl($_[0], $DURATION_GRAMMAR);
}




#GRAMMAR HANDLER ROUTINES


*getter = \&Criteria::Compile::getter;

sub _dt_to_unix {
    
    my $dt = $_[0];
    #convert datetime to unixtime
    $dt = $dt->epoch()
        if (ref($dt) eq 'DateTime');
    #return unixtime or undef
    return ($dt =~ /^\d+$/)
        ? $dt
        : undef;
}


sub _del_to_dur {

    my $del = $_[0];
    #convert delta to duration
    return $del 
        if (ref($del) eq DURATION_CLASS());
    return DURATION_CLASS()->new(%$del)
        if (ref($del) eq 'HASH');
}


sub _gen_before_sub {

    my ($context, $val, $attr) = @_;

    #check arguments
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'before',
        'No attribute supplied.')
        unless ($attr);

    #check value is usable for comparison
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'before',
        'Value not a valid datetime or unixtime value')
        unless (($val = _dt_to_unix($val)) ne '');

    #return handler sub
    my $getter = $context->{getter};
    return sub {
        return (ref($_[0])
            and (local $_ = $getter->($_[0], $attr)))
            ? ($_->epoch() < $val)
            : 0;
    };
}


sub _gen_after_sub {

    my ($context, $val, $attr) = @_;

    #check arguments
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'after',
        'No attribute supplied.')
        unless ($attr);

    #check value is usable for comparison
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'after',
        'Value not a valid datetime or unixtime value')
        unless (($val = _dt_to_unix($val)) ne '');

    #return handler sub
    my $getter = $context->{getter};
    return sub {
        return (ref($_[0])
            and (local $_ = $getter->($_[0], $attr)))
            ? ($_->epoch() > $val)
            : 0;
    };
}


sub _gen_sooner_than_sub {

    my ($context, $val, $attr) = @_;

    #check arguments
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'sooner_than',
        'No attribute supplied.')
        unless ($attr);

    #check value is usable for comparison
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'sooner_than',
        'Value not a valid duration value')
        unless (ref($val = _del_to_dur($val)));

    #return handler sub
    my $getter = $context->{getter};
    Carp::croak('Getter not defined!') unless ($getter);
    return sub {
        return (ref($_[0])
            and (local $_ = $getter->($_[0], $attr)))
            ? ($_->epoch() < DATETIME_CLASS()->now()->add_duration($val)->epoch())
            : 0;
    };
}


sub _gen_later_than_sub {

    my ($context, $val, $attr) = @_;

    #check arguments
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'later_than',
        'No attribute supplied.')
        unless ($attr);

    #check value is usable for comparison
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'later_than',
        'Value not a valid duration value')
        unless (ref($val = _del_to_dur($val)));

    #return handler sub
    my $getter = $context->{getter};
    return sub {
        return (ref($_[0])
            and (local $_ = $getter->($_[0], $attr)))
            ? ($_->epoch() > DATETIME_CLASS()->now()->add_duration($val)->epoch())
            : 0;
    };
}


sub _gen_shorter_than_sub {

    my ($context, $val, $attr) = @_;

    #check arguments
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'shorter_than',
        'No attribute supplied.')
        unless ($attr);

    #check value is usable for comparison
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'shorter_than',
        'Value not a valid duration value')
        unless (ref($val = _del_to_dur($val)));

    #return handler sub
    my $getter = $context->{getter};
    return sub {
        return (ref($_[0])
            and (local $_ = $getter->($_[0], $attr)))
            ? (DURATION_CLASS()->compare($val, $_) > 0 ? 1 : 0)
            : 0;
    };
}


sub _gen_longer_than_sub {

    my ($context, $val, $attr) = @_;

    #check arguments
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'longer_than',
        'No attribute supplied.')
        unless ($attr);

    #check value is usable for comparison
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'longer_than',
        'Value not a valid duration value')
        unless (ref($val = _del_to_dur($val)));

    #return handler sub
    my $getter = $context->{getter};
    return sub {
        return (ref($_[0])
            and (local $_ = $getter->($_[0], $attr)))
            ? (DURATION_CLASS()->compare($val, $_) < 0 ? 1 : 0)
            : 0;
    };
}



sub _gen_newer_than_sub {

    my ($context, $val, $attr) = @_;

    #check arguments
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'newer_than',
        'No attribute supplied.')
        unless ($attr);

    #check value is usable for comparison
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'newer_than',
        'Value not a valid duration value')
        unless (ref($val = _del_to_dur($val)));

    #return handler sub
    my $getter = $context->{getter};
    return sub {
        return (ref($_[0])
            and (local $_ = $getter->($_[0], $attr)))
            ? (DURATION_CLASS()->compare(
                DATETIME_CLASS()->now->subtract_datetime($_),
                $val) < 0 ? 1 : 0)
            : 0;
    };
}


sub _gen_older_than_sub {

    my ($context, $val, $attr) = @_;

    #check arguments
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'older_than',
        'No attribute supplied.')
        unless ($attr);

    #check value is usable for comparison
    die sprintf(Criteria::Compile::HANDLER_DIE_MSG(), 'older_than',
        'Value not a valid duration value')
        unless (ref($val = _del_to_dur($val)));

    #return handler sub
    my $getter = $context->{getter};
    return sub {
        return (ref($_[0])
            and (local $_ = $getter->($_[0], $attr)))
            ? (DURATION_CLASS()->compare(
                DATETIME_CLASS()->now->subtract_datetime($_),
                $val) > 0 ? 1 : 0)
            : 0;
    };
}





1;
