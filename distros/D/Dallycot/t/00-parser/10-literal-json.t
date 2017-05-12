use lib 't/lib';

use Test::More;
use ParserHelper;

test_parses(
  '{ "foo": 3 }' => [
    jsonObject(
      jsonProperty(
        "foo", intLit(3)
      )
    )
  ],
  q[
   {
     "@context": [
       <https://www.dhdata.org/ns/linked-code/1.0.json>,
       {
         ns:l := <http://www.example.com/our-library#>,
         "@base": <http://www.example.com/our-library#>,
       }
     ],
     "@id": <http://www.example.com/our-library>,
     "@type": <lc:Library>,
     "label": "Example Library",
     "members": [
       repeated := (
         f(ff, s) :> [ s, ff(ff,s) ];
         f(f, _)
       ),
       ones := repeated(1)
     ]
   }
  ] => [
    jsonObject(
      jsonProperty(
        '@context',
        jsonArray(
          uriLit('https://www.dhdata.org/ns/linked-code/1.0.json'),
          jsonObject(
            xmlns_def('l', stringLit('http://www.example.com/our-library#')),
            jsonProperty('@base', uriLit('http://www.example.com/our-library#'))
          )
        )
      ),
      jsonProperty('@id', uriLit('http://www.example.com/our-library')),
      jsonProperty('@type', uriLit('lc:Library')),
      jsonProperty('label', stringLit('Example Library')),
      jsonProperty('members', jsonArray(
        assignment('repeated', sequence(
          assignment('f', lambda(
            [ 'ff', 's' ],
            {},
            list(
              fetch('s'),
              apply(
                fetch('ff'),
                fetch('ff'),
                fetch('s')
              )
            )
          )),
          apply(
            fetch('f'),
            fetch('f'),
            placeholder(),
          )
        )),
        assignment('ones', apply(
          fetch('repeated'),
          intLit(1)
        ))
      ))
    )
  ],

  '
  {
    "bar": [ "a", "b", 1, 2 ],
    "foo": {
      "apples": 3,
      "bananas": 4
    }
  }
  ' => [
    jsonObject(
      jsonProperty(
        "bar", jsonArray(
          stringLit("a"),
          stringLit("b"),
          intLit(1),
          intLit(2),
        )
      ),
      jsonProperty(
        "foo", jsonObject(
          jsonProperty( "apples", intLit(3) ),
          jsonProperty( "bananas", intLit(4) ),
        )
      ),
    )
  ],
  q{
    ({
      "@context": <http://example.com/context>,
      "expression": {
        "a": "Sum",
        "expressions": [ ]
      }
    })(3)
  } => [
    apply(
      jsonObject(
        jsonProperty( '@context', uriLit('http://example.com/context') ),
        jsonProperty( 'expression', jsonObject(
          jsonProperty( 'a', stringLit("Sum") ),
          jsonProperty( 'expressions', jsonArray())
        ))
      ),
      intLit(3)
    )
  ],

  # q{
  #   {
  #     "@context": [
  #       <http://www.dhdata.org/ns/linked-code/1.0.json>,
  #       <http://www.jamesgottlieb.com/ns/genealogy/1.0.json>
  #     ],
  #     "@id": <http://www.jamesgottlieb.com/ns/genealogy/1.0/Person>,
  #     "@type": ["rdfs:Class", "lc:Library"],
  #     "label": "Person Class",
  #     "members": [
  #
  #       (*
  #         Given a person, returns a stream with their parents either by birth
  #         or by nurture. Does not consider families
  #       *)
  #       parents := (
  #         by-nature := (
  #           process-births-f(ff, s) :> [ s' -> "mother", s' -> "father", ff(ff, s...) ];
  #           { process-births-f(process-births-f, #->"births") }
  #         );
  #
  #         by-nurture := (
  #           process-families-f(ff, person, s) :> (
  #             (0 < length({# = person } % (s' -> "children")) < inf) : (
  #               (s' -> :spouses) ::: ff(ff, person, s...)
  #             )
  #             ( ) : ff(ff, person, s...)
  #           );
  #           { process-families-f(process-families-f, #, #->"families") }
  #         );
  #
  #         parents(person, by -> "Nature" ) :> (
  #           (by = "Nature") : (by-nature(person))
  #           (by = "Nurture") : (by-nurture(person))
  #           ( ) : ( [] )
  #         );
  #       ),
  #
  #       (*
  #         Given a person, returns their parents' parents. Handles nurture vs.
  #         nature by passing the option to the parent function.
  #       *)
  #       grand-parents := (
  #         process-parents-f(ff, s, by) :> (
  #           (parents(s', by -> by)) ::: ff(ff, s..., by -> by)
  #         );
  #         grand-parents(person, by -> "Nature") :>
  #           process-parents-f(process-parents-f, parents(person, by->by), by);
  #       )
  #     ]
  #   }
  # } => [
  #
  # ],

  # q{
  # {
  #   "@context": [
  #     <http://www.dhdata.org/ns/linked-code/1.0.json>,
  #     {
  #
  #     }
  #   ],
  #   "@id": <http://www.example.com/adventure>,
  #   "@type": "lc:Library",
  #   "label": "Adventure",
  #   "members": [
  #     make-game() :> {
  #       @type := "Game",
  #       locations := [],
  #       objects := []
  #     },
  #
  #     make-location(game, location, long-desc, short-desc, flags) :> (
  #       loc := {
  #         @id := "room:" + location,
  #         @type := "Room",
  #         label := location,
  #         description := long-desc,
  #         brief := short-desc,
  #         flags := flags,
  #         times-here := 0,
  #         instructions := [],
  #         location-count := length(game -> locations),
  #       };
  #       game / {
  #         last-location := loc,
  #         locations := loc ::> game -> locations
  #       }
  #     ),
  #
  #     make-instruction(game, word-string, cond, dest) :> (
  #       inst := {
  #         @type := "Word",
  #         word := word-string,
  #         environment := game -> last-location,
  #         condition := cond,
  #         remark := (
  #           (dest = "sayit") : (game -> remark-string)
  #           ( ) : ( )
  #         ),
  #         destination := (
  #           (dest = "sayit") : ( )
  #           ( ) : ("room:" + dest)
  #         )
  #       };
  #       game / {
  #         last-location := game -> last-location / {
  #           instructions := inst ::> game -> last-location -> instructions
  #         }
  #       }
  #     ),
  #
  #     ditto(game, word-string) :> (
  #       inst := game -> last-location -> instructions' / {
  #         word := word-string
  #       };
  #       game / {
  #         last-location := game -> last-location / {
  #           instructions := inst ::> game -> last-location -> instructions
  #         }
  #       }
  #     ),
  #
  #     force(game, dest, c) :> (
  #       cond := (
  #         (?c) : (c)
  #         (  ) : { false }/0
  #       );
  #       make-instruction(game, "FORCE", c, dest)
  #     ),
  #
  #     item(game, id) :> { # -> @id = id } % game -> objects,
  #
  #     at-location?(game, treasure, location) :> (
  #       item(game, treasure) -> environment = location
  #     ),
  #
  #     toting?(game, treasure) :> at-location?(game, treasure, "player"),
  #
  #
  #   ]
  # }
  # } => [],
);

done_testing();
