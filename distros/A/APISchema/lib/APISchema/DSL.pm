package APISchema::DSL;
use strict;
use warnings;

# lib
use APISchema::Schema;

# core
use Carp ();

# cpan
use Exporter 'import';
use Path::Class qw(file);

my %schema_meta = (
    ( map { $_ => "${_}_resource" } qw(request response) ),
    ( map { $_ => $_ } qw(title description destination option) ),
);

our %METHODS = (
    ( map { $_ => $_ } qw(HEAD GET POST PUT DELETE PATCH) ),
    FETCH => [qw(GET HEAD)],
);
our @DIRECTIVES = (qw(include filter resource title description), keys %METHODS);
our @EXPORT = @DIRECTIVES;

my $_directive = {};

sub process (&) {
    my $dsl = shift;

    my $schema = APISchema::Schema->new;

    local $_directive->{include} = sub {
        my ($file) = @_;
        -r $_[0] or Carp::croak(sprintf 'No such file: %s', $file);
        my $content = file($file)->slurp;
        my $with_utf8 = "use utf8;\n" . $content;
        eval $with_utf8;
        Carp::croak($@) if $@;
    };
    local $_directive->{title} = sub {
        $schema->title(@_);
    };
    local $_directive->{description} = sub {
        $schema->description(@_);
    };

    my @filters;
    local $_directive->{filter} = sub {
        push @filters, $_[0];
    };
    local $_directive->{resource} = sub {
        $schema->register_resource(@_);
    };

    local @$_directive{keys %METHODS} = map {
        my $m = $_;
        sub {
            my ($path, @args) = @_;
            for my $filter (reverse @filters) {
                local $Carp::CarpLevel += 1;
                @args = $filter->(@args);
            }
            my ($definition, $option) = @args;

            $schema->register_route(
                ( map {
                    defined $definition->{$_} ?
                        ( $schema_meta{$_} => $definition->{$_} ) : ();
                } keys %schema_meta ),
                defined $option ? (option => $option) : (),
                route  => $path,
                method => $METHODS{$m},
            );
        };
    } keys %METHODS;

    $dsl->();
    return $schema;
}

# dispatch directives to the definitions
sub include ($) { $_directive->{include}->(@_) }
sub title ($) { $_directive->{title}->(@_) }
sub description ($) { $_directive->{description}->(@_) }
sub filter (&) { $_directive->{filter}->(@_) }
sub resource ($@) { $_directive->{resource}->(@_) }
for my $method (keys %METHODS) {
    no strict 'refs';
    *$method = sub ($@) { goto \&{ $_directive->{$method} } };
}

# disable the global definitions
@$_directive{@DIRECTIVES} = (sub {
    Carp::croak(sprintf(
        q(%s should be called inside 'process {}' block),
        join '/', @DIRECTIVES
    ));
}) x scalar @DIRECTIVES;

1;
__END__
