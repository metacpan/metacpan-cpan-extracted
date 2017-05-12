# NAME

Data::Iterator::SlidingWindow - Iteration data with Sliding Window Algorithm

# SYNOPSIS

     use Data::Iterator::SlidingWindow;
    
     my $ i = 0;
     my $iter = iterator 3 => sub{
         #generate/fetch next one.
         return if $i > 6;
         return $i++;
     };
    
     while(defined(my $cur = $iter->next())){
         # $cur is [1, 2, 3], [2, 3, 4], [3, 4, 5], [4, 5, 6]
     }
    

And you can use <> operator.

       while(<$iter>){
           my $cur = $_;
           ....
       }
    
    

# DESCRIPTION

This module is iterate elements of Sliding Window.

# METHODS

## iterator($window\_size, $data\_source) 

Iterator constructor.
The arguments are:

- $window\_size 

    Windows size. 

- $data\_source

    Data source of iterator.

    CODE reference:

        iterator 3 => sub{
            CODE
        };
        

    CODE returns a value on each call, and if it is exhausted, returns undef.
    If you want yield undefined value as a meaning value.You can use 'NULL object pattern'.

        iterator 3 => sub{
           my $value = generate_next_value();
           return unless is_valid_value($value); # exhausted!
           return { value => $value };
        };

    ARRAY reference:

        iterator 3 => \@array;

## next()

Get next window.

# AUTHOR

Hideaki Ohno <hide.o.j55{at}gmail.com>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
