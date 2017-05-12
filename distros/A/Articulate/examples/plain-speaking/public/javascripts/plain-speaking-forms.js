;(function($){
  $( document ).ready(function() {
    $('form').each(function(){
      thisForm = $(this);
      thisForm.find('button.submit-form').click(function(){
        thisForm.submit();
      });
      thisForm.find('.submit-form-preview').click(function(event){
        event.stopPropagation();
        event.preventDefault();
        var formTarget = thisForm.prop('target');
        var formUrl    = thisForm.prop('action');
        thisForm.prop( 'target', '_blank'    );
        thisForm.prop( 'action', './preview '); //'./'+thisForm.find('[name=article_id]').first().val()+'/preview' );
        thisForm.submit(); // actually no, we want to open a post request in new window.
        thisForm
          .prop( 'target', formTarget )
          .prop( 'action', formUrl );
      });
    });
  });
})(jQuery);
