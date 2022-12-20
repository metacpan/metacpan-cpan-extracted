const d = document;
const selectToC = d.getElementById('selectToC');
const options = Array.from(selectToC.options)
  .map(opt => { return { key: opt.value, div: d.getElementById(opt.value) }; });
selectToC.addEventListener(
  'change',
  (event) => {
    options.forEach(opt => {
      if (!opt.div) { return; }
      if (opt.key == selectToC.value) {
        opt.div.classList.remove('hide');
      } else {
        opt.div.classList.add('hide');
      }
    });
  }
);
