use MooseX::Declare;

class App::Syndicator::Types {
    use Moose::Util::TypeConstraints;
    use MooseX::Types::Moose qw/Object ArrayRef Str Int Bool/;
    use MooseX::Types -declare=> [qw/
        Entry_T DateTime_T UriArray Window_T Aggregator_T
        DB_T Importer_T PositiveInt File 
        WritableFile TextViewer_T KiokuDB_T
        Curses_T Output_T ListBox_T MessageBody_T MessageTitle_T
        Message_T
    /];
    use MooseX::Types::URI 'Uri';
    use MooseX::Types::DateTime 'DateTime';
    use IO::All;
    
    subtype UriArray,
        as ArrayRef[Uri];
    coerce UriArray,
        from ArrayRef[Str],
        via sub {
            [ map { Uri->coerce($_) } @{$_[0]} ];
        };

    subtype DateTime_T,
        as DateTime;

    subtype File,
        as Str,
        where {
            -f $_;
        },
        message {"\n\n This '$_' is not a file\n\n" };

    subtype WritableFile,
        as Str,
        where {
            io($_)->touch unless -f $_;
            -f && -w;
        },
        message {"\n\n Couldn't create or write to file '$_'"};

    subtype PositiveInt,
        as Int,
        where { 
            $_ > -1;
        };

    subtype Entry_T,
        as Object,
        where {
            $_->isa('XML::Feed::Entry')
        },
        message {"expecting Entry object"};
    

    class_type Aggregator_T, { class => 'XML::Feed::Aggregator' };
    class_type KiokuDB_T, { class => 'KiokuDB' };
    class_type Importer_T, { class => 'App::Syndicator::Importer' };
    class_type Message_T, { class => 'App::Syndicator::Message' };
    class_type DB_T, { class => 'App::Syndicator::DB' };
    class_type TextViewer_T, { class => 'Curses::UI::TextViewer' };
    class_type ListBox_T, { class => 'Curses::UI::Listbox' };
    class_type Window_T, { class => 'Curses::UI::Window' };
    class_type Curses_T, { class => 'Curses::UI' };
}
