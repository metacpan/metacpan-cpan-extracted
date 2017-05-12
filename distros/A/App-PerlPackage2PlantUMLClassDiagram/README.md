# NAME

package2plantumlclassdiagram - Generates Plant UML's Class Diagram from Perl Modules

# DESCRIPTION

package2plantumlclassdiagram analyze Perl modules with PPI, and generate Plant UML's Class Diagram syntax.

You can render the output result with PlantUML.

[Output Example is here.](https://gist.github.com/hitode909/ce22c46004f2ff1dac73)

# SYNOPSIS

    % package2plantumlclassdiagram PATH_TO_MODULES > a.plantuml

Then, render a.plantuml with PlantUML.

    % GRAPHVIZ_DOT=$(which dot) plantuml -charset UTF-8 -tpng a.plantuml
    % open a.png

# PLOT ALL MODULES I YOUR PROJECT

Like this.

    % package2plantumlclassdiagram ~/YourApp/lib/**/**.pm > a.plantuml

# PLOT ONLY INHERITANCE RELATIONSHIPS

Use grep -P.

    % package2plantumlclassdiagram PATH_TO_MODULES | ggrep -P '^(@startuml|@enduml)|(<|--)' > a.plantuml

# SEE ALSO

[http://plantuml.com/classes.html](http://plantuml.com/classes.html)

# LICENSE

Copyright (C) hitode909.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

hitode909 <hitode909@gmail.com>
