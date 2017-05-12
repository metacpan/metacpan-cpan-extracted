package App::yajg::Output;

use 5.014000;
use strict;
use warnings;
use utf8;

use App::yajg;
use Data::Dumper qw();

# Class methods
sub new { bless {}, shift }

{
    my $can_hl = eval {
        # FIXME: probably will not work if not unix os
        qx(which highlight 2>/dev/null) and $? == 0
    };
    sub can_highlight {$can_hl}
}

sub lang              {...}    # lang for highlight
sub need_change_depth {1}      # need to change max depth via Data::Dumper

sub highlight {
    my ($class, $string) = @_;
    $class = ref $class if ref $class;

    return $string unless $class->can_highlight and length $string;

    # IPC::Open2 hangs on big data so we will do like this
    my $pid = open(my $hl_out, '-|');
    if (not defined $pid) {
        warn "highlight failed: $!\n";
        return $string;
    }
    my $utf8 = utf8::is_utf8($string);

    unless ($pid) {
        open(my $hl_in, '|-', 'highlight', '-O', 'ansi', '-S', $class->lang)
          or die "$!\n";
        utf8::encode($string) if utf8::is_utf8($string);
        print $hl_in $string;
        close $hl_in;
        exit 0;
    }

    local $/;
    my $highlighted = <$hl_out>;
    close $hl_out;    # may be waitpid($pid, 0); ??
    return $string unless $? == 0;
    utf8::decode($highlighted) if $utf8 and not utf8::is_utf8($highlighted);

    return $highlighted || $string;
}

# Object methods

# Getters/Setters
for my $method (qw(data color minimal max_depth sort_keys escapes)) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$method" } = sub {
        my $self = shift;
        return $self->{ '_' . $method } unless @_;
        $self->{ '_' . $method } = shift;
        return $self;
    };
}

sub change_depth {
    my $self  = shift;
    my $class = ref $self;
    return $self unless $class->need_change_depth and $self->max_depth;
    local $SIG{__WARN__} = \&App::yajg::warn_without_line;
    # TODO: fails to restore true, false when depth and boolean at same level
    #       but we can restore 1 or 0 or maybe 'true' 'false' (depend on version)
    my $VAR1;
    my $code = Data::Dumper->new([$self->data])->Maxdepth($self->max_depth)->Dump();
    # 2x eval to prevent problems with max depth and boolean type
    # Deepcopy has no effect when depth 1 and true/false =(
    eval $code; eval $code;
    if ($@ or not defined $VAR1) {
        warn "max_depth failed: $@";
    }
    else {
        $self->data($VAR1);
    }
    return $self;
}

sub as_string {
    ...
}

sub print {
    my $self  = shift;
    my $class = ref $self;
    my $out   = $self->change_depth->as_string;
    $out = $class->highlight($out) if $self->color and $class->can_highlight;
    utf8::encode($out) if utf8::is_utf8($out);
    $out .= "\n" unless $out =~ m/\n\z/;
    print $out;
    return $self;
}

1;
