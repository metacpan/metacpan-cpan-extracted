package App::BCSSH::Pod;
use strictures 1;

use base qw(Pod::Simple::PullParser Pod::Simple::Text);

use Module::Reader qw(:all);

sub new {
    my $class = shift;
    my $self = $class->Pod::Simple::PullParser::new;
    my $alt = $class->Pod::Simple::Text::new;
    @$self{keys %$alt} = values %$alt;
    return $self;
}

sub parse {
    my $self = ref $_[0] ? shift : shift->new;
    my $source = shift;
    my $fh = module_handle($source, { found => \%INC } );
    $self->set_source($fh);

    my %return;
    local $self->{_return} = \%return;

    while (my $token = $self->get_token) {
        if ($token->is_start && $token->tagname eq 'head1') {
            my $next = $self->get_token;
            if ($next->is_text and my $meth = $self->can('_pull_' . $next->text)) {
                while (my $ff = $self->get_token) {
                    last if $ff->is_end && $ff->tag eq 'head1';
                }
                $self->$meth();
            }
            else {
                $self->unget_token($next);
            }
        }
    }
    return \%return;
}

sub _pull_NAME {
    my $self = shift;
    my $abstract = $self->_pull_head1_text;
    $abstract =~ s/.*?\s+-\s+//;
    $self->{_return}{abstract} = $abstract;
}

sub _pull_SYNOPSIS {
    my $self = shift;
    $self->{_return}{synopsis} = $self->_pull_head1_text;
}

sub _pull_head1_text {
    my $self = shift;
    my $text = '';
    while (my $next = $self->get_token) {
        $text .= $next->text if $next->is_text;
        if ($next->is_start && $next->tag =~ /^[a-z]/) {
            $self->unget_token($next);
            last;
        }
    }
    return $text;
}

sub _pull_OPTIONS {
    my $self = shift;
    my %options;
    $self->{_return}{options} = \%options;
    while (my $ff = $self->get_token) {
        last if $ff->is_start && $ff->tag =~ /^over-/;
    }
    while (my $items = $self->get_token) {
        last
            if $items->is_end && $items->tag =~ /^over-/;
        next
            unless $items->is_start && $items->tag =~ /^item-/;

        my $option = '';
        while (my $opt = $self->get_token) {
            last if $opt->is_end && $opt->tag =~ /^item-/;
            $option .= $opt->text if $opt->is_text;
        }

        my $opt_text = '';
        my $depth = 1;
        open my $fh, '>', \$opt_text;
        local $self->{output_fh} = $fh;
        while (my $opt = $self->get_token) {
            if (! $opt->is_text && $opt->tag =~ /^over-/) {
                $depth += $opt->is_start ? 1 : -1;
                last if $depth == 0;
            }

            if ($opt->is_text) {
                $self->handle_text($opt->text);
                next;
            }
            my $m = $opt->type . '_' . $opt->tag;
            $self->can($m) or next;

            $self->$m( $opt->is_start ? $opt->attr_hash : () );
        }
        $opt_text =~ s/^    //gm;
        $opt_text =~ s/\n\n$//;

        $options{$option} = $opt_text;
    }
}

1;
__END__

=head1 NAME

App::BCSSH::Pod - Read Pod abstract, synopsis, and options from loadable modules

=head1 SYNOPSIS

    my $parsed = App::BCSSH::Pod->parse($package);
    my ($abstract, $synopsis, $options) = @{$parsed}{qw(abstract synopsis options)};

=cut
