use MooseX::Declare;

class App::Syndicator::Message with App::Syndicator::HtmlToAscii {
    use MooseX::Types::Moose qw/Str Bool/;
    use MooseX::Types::URI 'Uri';
    use MooseX::Types::DateTime;
    use DateTime;
    use App::Syndicator::Types ':all';
    use Digest::MD5 'md5_base64';

    has title => (
        is => 'rw',
        isa => Str,
        lazy_build => 1,
        required => 1,
    );

    has body => (
        is => 'rw',
        isa => Str,
        lazy_build => 1,
        required => 1,
    );

    has author => (
        isa => Str,
        is => 'rw',
        required => 1,
        lazy_build => 1,
    );

    has id => (
        isa => Str,
        is => 'rw',
        required => 1,
        lazy_build => 1
    );

    has published => (
        is => 'rw',
        coerce => 1,
        isa => 'DateTime',
        lazy_build => 1,
        required => 1
    );

    has format => (
        is => 'rw',
        isa => Str,
        lazy_build => 1,
        required => 1
    );

    has uri => (
        is => 'rw',
        isa => Uri,
        coerce => 1,
        lazy_build => 1,
        required => 1,
        handles => {link => 'as_string'}
    );

    has base_uri => (
        is => 'rw',
        isa => Uri,
        coerce => 1,
        lazy_build => 1,
        handles => {base_link => 'as_string'}
    );

    has is_read => (
        is => 'rw',
        isa => Bool,
        default => 0,
    );

    has is_deleted => (
        is => 'rw',
        isa => Bool,
        default => 0,
    );

    has star => (
        is => 'rw',
        isa => Bool,
        default => 0,
    );

    has xml_entry => (
        is => 'rw',
    );

    method BUILDARGS(ClassName $class: Entry_T $entry) {
        return $class->next::method({xml_entry => $entry});
    }

    method delete {
        $self->title('');
        $self->body('');
        $self->star(0);
        $self->is_deleted(1);
    }

    method BUILD {
        if (my $entry = $self->xml_entry) {
            $self->uri($entry->link);
            $self->base_uri($entry->base) if defined $entry->base;

            $self->author($entry->author) 
                if defined $entry->author;

            my $title = $self->html_to_ascii($entry->title);
            chomp $title;
            $title =~ s/^\s+(.+)$/$1/;
            $title =~ s/\s+/ /g;
            $self->title($title);

            $self->published(
                $entry->modified || $entry->issued || DateTime->now
            );

            my $content = $entry->content->body;  
            my $summary = $entry->summary->body;

            if (defined $content && length($content)) {
                $self->body($self->html_to_ascii($content));
            }
            elsif (defined $summary && length($summary)) {
                $self->body($self->html_to_ascii($summary))
            }
            else {
                die "no body for this message!";
            }

            $self->id(
                md5_base64(
                    $entry->id,
                    $self->published
                )
            );

            $self->xml_entry(undef);
        }
    }

    # should really be in a view.
    method render_title {
        return ($self->is_read ? '' : '<bold>[NEW] </bold>')
            . ($self->star ? '<bold>[*] </bold>' : '')
            . $self->title;
    }
}

