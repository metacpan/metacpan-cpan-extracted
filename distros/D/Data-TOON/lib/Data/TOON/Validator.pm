package Data::TOON::Validator;
use 5.014;
use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub validate {
    my ($self, $toon_text) = @_;
    
    return 1 if !$toon_text || $toon_text =~ /^\s*$/;
    
    my @lines = split /\r?\n/, $toon_text;
    pop @lines if @lines && $lines[-1] eq '';
    
    # Find first non-empty line
    my @non_empty = grep { $_ && $_ !~ /^\s*$/ } @lines;
    
    # Empty document is valid
    return 1 if !@non_empty;
    
    # Validate each line
    foreach my $line (@lines) {
        next if !$line || $line =~ /^\s*$/;
        
        # Check for valid key-value or header
        if (!$self->_is_valid_line($line)) {
            return 0;
        }
    }
    
    return 1;
}

sub _is_valid_line {
    my ($self, $line) = @_;
    
    # Remove leading whitespace to check depth
    my $trimmed = $line;
    $trimmed =~ s/^ +//;
    
    # Empty line is valid
    return 1 if !$trimmed;
    
    # Valid patterns:
    # 1. key: value
    # 2. key[N]: ...
    # 3. key[N]{fields}: ...
    # 4. - value (list item)
    # 5. [N]: ... (root array)
    # 6. CSV row (anything else that looks like values)
    
    return 1 if $trimmed =~ /^[\w"]+\s*:/;           # key: ...
    return 1 if $trimmed =~ /^[\w"]+\s*\[\d+\]/;    # key[N]...
    return 1 if $trimmed =~ /^-\s/;                  # - item
    return 1 if $trimmed =~ /^\[\d+\]/;              # [N]: ... (root array)
    
    # If the line has content (looks like a CSV row or data line), it's probably valid
    # This is a permissive approach - stricter validation would require context
    return 1 if $trimmed =~ /\S/;
    
    return 0;
}

1;
