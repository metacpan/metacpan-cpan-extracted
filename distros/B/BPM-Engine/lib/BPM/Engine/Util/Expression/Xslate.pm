package BPM::Engine::Util::Expression::Xslate;
BEGIN {
    $BPM::Engine::Util::Expression::Xslate::VERSION   = '0.01';
    $BPM::Engine::Util::Expression::Xslate::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
use Text::Xslate;
use Template::Stash;
use BPM::Engine::Exceptions qw/throw_expression throw_abstract/;
extends 'BPM::Engine::Util::Expression::Base';

my $_engine = Text::Xslate->new(
    function => { 
        #attribute => sub { ... } 
        },
    module => ['Text::Xslate::Bridge::TT2Like'], # 'Text::Xslate::Bridge::Alloy',
    syntax => 'TTerse',
    verbose => 1,
    warn_handler => sub {
        my $warning = shift;
        throw_expression error => "Invalid template syntax: $warning";
        },
    );

sub _render {
    my ($self, $template, $args) = @_;
    
    $args ||= $self->params;
    $template = '[% ' . $template . ' %]' unless $template =~ /(\[%|%\])/;
    
    my $content;
    eval {
        # guard with timeout against infinite loops etc
        local $SIG{ALRM} = sub { die "Timed out processing expression\n" }; # \n required
        alarm 1;
        $content = $_engine->render_string($template, $args);
        alarm 0; # restore
        };
    
    if(my $err = $@) {
        throw_expression error => qq/Couldn't render template "$err"/;
        }

    return $content;
    }

sub evaluate {
    my ($self, $expr) = @_;
    return 0 unless $expr;

    my $boolean = $self->_render($expr) || 0;

    throw_expression("Condition eval '$expr': $boolean not a number") 
        unless $boolean =~ /^\d$/;
    throw_expression("Condition eval '$expr': $boolean not boolean (0 or 1)") 
        unless ($boolean == 0 || $boolean == 1);

    return $boolean;
    }

sub render {
    my ($self, $expr) = @_;
    
    my $args = $self->params;
    my $output_buffer = '';
    $args->{output} = sub { $output_buffer = $_[0]; };

    my $output = $self->_render("output($expr)", $args);
    $output = $output_buffer if $output_buffer;

    return $output;
    }

sub assign {
    my ($self, $trg, $expr) = @_;

    if(ref($trg))  { $trg  = $trg->{content};  }
    if(ref($expr)) { $expr = $expr->{content}; }

    my $output = $self->render($expr);
    
    my $pi = $self->process_instance;
    my ($root, @junk) = split(/\./, $trg);
    if(scalar @junk) {
        my $stash = Template::Stash->new();
        my $attrib = $pi->attribute($root)->value;
        $stash->set($root, $attrib);        
        eval{        
            # set rvalue output as lvalue val, merging with $root
            $stash->set($trg, $output);
            };
        if(my $err = $@) {
            throw_expression error => qq/Couldn't set rvalue: "$err"/;
            }
        $pi->attribute($root => $stash->get($root));
        }
    else {
        $pi->attribute($root => $output);
        }
    
    }

sub dotop {
    my ($self, $trg) = @_;
    return $self->render('var.' . $trg);
    }

__PACKAGE__->meta->make_immutable;

1;
__END__
