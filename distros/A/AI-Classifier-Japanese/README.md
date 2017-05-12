# NAME

AI::Classifier::Japanese - the combination wrapper of Algorithm::NaiveBayes and
Text::MeCab.

# SYNOPSIS

    use AI::Classifier::Japanese;

    # Create new instance
    my $classifier = AI::Classifier::Japanese->new();

    # Add training text
    $classifier->add_training_text("たのしい．楽しい！", 'positive');
    $classifier->add_training_text("つらい．辛い！", 'negative');

    # Train
    $classifier->train;

    # Test
    my $result_ref = $classifier->predict("たのしい");
    print $result_ref->{'positive'}; # => Confidence value

# DESCRIPTION

AI::Classifier::Japanese is a Japanese-text category classifier module using Naive Bayes and MeCab.
This module is based on Algorithm::NaiveBayes.
Only noun, verb and adjective are currently supported.

# METHODS

- `my $classifier = AI::Classifier::Japanese->new();`

    Create new instance of AI::Classifier::Japanese.

- `$classifier->add_training_text($text, $category);`

    Add training text.

- `$classifier->train;`

    Train.

- `my $result_ref = $classifier->predict($text);`

    Test and returns a predicted result hash reference which has a confidence value for each category.

- `$classifier->save_state($params_path);`

    Save parameters.

- `$classifier->restore_state($params_path);`

    Restore parameters from a file.

- `my @labels = $classifier->labels;`

    Get category labels as an array reference.

# LICENSE

Copyright (C) Shinichi Goto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Shinichi Goto <shingtgt @ GMAIL COM>
