# NAME

Captcha::Stateless::Text - stateless, text-based CAPTCHAs

# DESCRIPTION

A module to make stateless, text-based CAPTCHAs easy to implement.
It supports:

    * Simple math:
        "7 + 3 = ?"
        answer = 10
    * Character selection:
        "Provide the second, third, and sixth characters from B-G-Q-E-O-S"
        answer = GQS

# SYNOPSIS

    use Captcha::Stateless::Text;

    my $captcha = Captcha::Stateless::Text->new();

    # Recommend setting these to values that *you* derive
    # Must be 16 bytes / 128 bits
    $captcha->set_iv('gkbx5g9hsvhqrosg');
    # 32 bytes / 256 bits for AES256
    $captcha->set_key('tyDjb39dQ20pdva0lTpyuiowWfxSSwa9');

    # Grab a question/answer data structure
    my $qa = $captcha->getQA_chars();
    #    __or__
    my $qa = $captcha->getQA_math();

    # For getQA_chars(), $qa will look similar to this:
    my $qa_chars = {
      'q' => 'Provide the first and fifth characters from A-W-N-Z-L-X'
      'a' => 'AL',
      'enc_payload' => <<base-64 and url-encoded encrypted data>>,
    },
    # For getQA_math(), $qa will look similar to this:
    my $qa_math = {
      'q' => '7 + 3',
      'a' => '10',
      'enc_payload' => <<base-64 and url-encoded encrypted data>>,
    };

    # Your job now is to present the user with the question ($qa->{q}), to
    # not lose the enc_payload (use a HTML <input type="hidden"> field), to
    # collect the user's answer, and then validate it, like this:
    my $is_valid = $captcha->validate($user_answer, $enc_payload_from_qa);
    if ($is_valid) {
      print "You win!\n";
    } else {
      print "You lose!\n";
    }

# SUBROUTINES

The two subroutines that generate the questions and answers have a few
options that can be specified to control their behavior.

    my $qa = $captcha->getQA_chars($q_len, $a_len, $q_sort);

    OPT   DEFAULT DESCRIPTION
    --------------------------------------------------------------------
    $q_len   6    The character length of the question string.
    $a_len   3    The number of characters in the answer.
    $q_sort  1    Sort the answer characters, so that users will always
                  be asked for characters flowing left-to-right, or
                  require them to "jump around" in the question string.

    my $qa = $captcha->getQA_math($a_max, $a_min);

    OPT   DEFAULT DESCRIPTION
    --------------------------------------------------------------------
    $a_max  11    The maximum value of the answer.
    $a_min   2    The minimum value of the answer.

# COPYRIGHT

Copyright (C) 2024, Lester Hightower <hightowe@cpan.org>

# LICENSE

This software is licensed under the OSI certified Artistic License,
one of the licenses of Perl itself.

[http://en.wikipedia.org/wiki/Artistic\_License](http://en.wikipedia.org/wiki/Artistic_License)
