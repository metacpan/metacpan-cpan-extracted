## Bug

1. References are not included in files.
2. When the references bump the slide count to 10, they are wrongly referenced from the HTML, resulting in empty slides

## Replicate

Compile and run beamer-reveal. Open resulting slides. Should be a few white
slides. Inspect the PDF, realize the slides should not be empty.
