'(data
  (org
   (name "shark"))
  (org
   (name "cow")
   (noise "moo")
   )
  (org
   (name "human") (sci "homo sapiens"))
  (org
   (name "grass")
   (colour "green")
   )
  (org
   (name "tuna")
   )
  (org 
   (name "aquatic_animal"))
  (rel
   (type "eats")
   (subj "human")
   (obj  "cow"))
  (rel
   (type "eats")
   (subj "human")
   (obj  "shark"))
  (rel
   (type "eats")
   (subj "human")
   (obj  "tuna"))
  (rel
   (type "eats")
   (subj "cow")
   (obj  "grass"))
  (rel
   (type "eats")
   (subj "shark")
   (obj  "human"))
  (rel
   (type "eats")
   (subj "shark")
   (obj  "tuna"))
  (rel
   (type "eats")
   (subj "human")
   (obj  "human")
   (qual "cannibalistic"))
  (rel
   (type "farms")
   (subj "human")
   (obj  "cow"))
  (rel
   (type "isa")
   (subj "tuna")
   (obj  "aquatic_animal"))
  (rel
   (type "isa")
   (subj "shark")
   (obj  "aquatic_animal"))
  (mapping
   (uid "name")
   (edge
    (tag "rel")
    (parent "obj")
    (child "subj")
    (att "*"))
   (vertex
    (tag "org")
    (att "name")
    (att "")
   )
  )
)


