c Zoom in and out, and Move picture around
c
	subroutine moveNzoom(xmin,xmax,ymin,ymax,value)
c
	integer*2 value
	integer*2 zoom_plus, zoom_minus
	integer*2 move_image_left, move_image_right, move_image_up, move_image_down

!	definitions
	move_image_up     = 81
	move_image_down   = 83
	move_image_right  = 82
	move_image_left   = 84
	zoom_plus  = 85
	zoom_minus = 86
c
!	write(*,*)
!	write(*,*) '** move_image cursor into the graphic screen **'
!	write(*,*)
!	write(*,*) 'i - zoom in,          o - zoom out'
!	write(*,*) 'k - move image up,    j - move image down'
!	write(*,*) 'l - move image right, h - move image left'
!	write(*,*)
!	write(*,*) '** Press any other key to leave **'
!	write(*,*)
c
!	read(*,'(a)') val
c

c Zoom in
	  if (value.eq.zoom_plus) then
	    dx = (xmax - xmin)/10
	    dy = (ymax - ymin)/10
c	    xmin = xmin + dx
c           xmax = xmax - dx
            xmax = xmax - 2.0*dx
            ymin = ymin + dy
            ymax = ymax - dy
	  endif
c Zoom out
	  if (value.eq.zoom_minus) then
	    dx = -(xmax - xmin)/8
	    dy = -(ymax - ymin)/8
	    xmin = xmin + dx
            xmax = xmax - dx
            ymin = ymin + dy
            ymax = ymax - dy
	  endif
c Move image down
	  if (value.eq.move_image_down) then
            dy = (ymax - ymin)/10
	    ymin = ymin - dy
	    ymax = ymax - dy!       format1= "(I2)"
          endif
c Move image up
	  if (value.eq.move_image_up) then
            dy = (ymax - ymin)/10
	    ymin = ymin + dy
            ymax = ymax + dy
          endif
c Move image to the right
	  if (value.eq.move_image_right) then
            dx = (xmax - xmin)/10
            xmin = xmin - dx
            xmax = xmax - dx
          endif
c Move image to the left
          if (value.eq.move_image_left) then
	    dx = (xmax - xmin)/10
            xmin = xmin + dx
            xmax = xmax + dx
          endif
c
	return
	end
