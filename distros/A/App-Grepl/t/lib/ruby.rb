#!/usr/bin/ruby

puts("This ain't Perl");
def some_method
    if block_given?
        this = 1
        that = 2
        yield(this, that)
    else 
        puts "what happened?"
    end
end

some_method { |x, y| puts x, y }
some_method
